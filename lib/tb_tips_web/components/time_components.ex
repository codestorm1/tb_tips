defmodule TbTipsWeb.TimeComponents do
  use Phoenix.Component
  import TbTipsWeb.CoreComponents

  @doc """
  Displays time in both TB reset format and local time
  """
  attr :datetime, :any, required: true
  attr :class, :string, default: ""

  def tb_time(assigns) do
    ~H"""
    <div class={@class}>
      <div class="font-medium text-gray-900">
        Reset {reset_hours(@datetime)}
      </div>
      <div
        class="text-sm text-gray-600"
        id={"local-time-#{System.unique_integer()}"}
        phx-hook="LocalTime"
        data-utc={DateTime.to_iso8601(@datetime)}
      >
        Loading local time...
      </div>
    </div>
    """
  end

  @doc """
  Time input that shows reset hours alongside datetime input
  """
  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, required: true
  attr :rest, :global

  def tb_time_input(assigns) do
    ~H"""
    <div class="space-y-2">
      <.input field={@field} type="datetime-local" label={@label} {@rest} />

      <%= if @field.value do %>
        <div class="p-2 bg-blue-50 rounded text-sm">
          <span class="font-medium">Preview:</span>
          <.tb_time datetime={parse_datetime_local(@field.value)} class="inline-block ml-2" />
        </div>
      <% end %>
    </div>
    """
  end

  # Calculate hours after reset (10am Pacific)
  defp reset_hours(datetime) when is_binary(datetime) do
    case DateTime.from_iso8601(datetime) do
      {:ok, dt, _} -> reset_hours(dt)
      _ -> "?"
    end
  end

  defp reset_hours(%DateTime{} = datetime) do
    # Simple UTC-based calculation
    # 10am Pacific = 6pm UTC (standard time) or 5pm UTC (DST)
    utc_reset_hour = if dst_active?(datetime), do: 17, else: 18

    # Get today's reset time in UTC
    today_reset = %{datetime | hour: utc_reset_hour, minute: 0, second: 0, microsecond: {0, 0}}

    # Calculate hours difference from today's reset
    diff_seconds = DateTime.diff(datetime, today_reset, :second)
    hours_diff = div(diff_seconds, 3600)

    cond do
      hours_diff >= 0 and hours_diff < 24 ->
        # Same day after reset: Reset +0 to Reset +23
        "+#{hours_diff}"

      hours_diff >= 24 ->
        # Next day(s): Reset +24, +25, etc.
        "+#{hours_diff}"

      hours_diff < 0 and hours_diff >= -24 ->
        # Before today's reset: Reset -1 to Reset -24
        "#{hours_diff}"

      true ->
        # More than 24 hours before: Reset -25, -26, etc.
        "#{hours_diff}"
    end
  end

  # Simple DST check (March-October rough approximation)
  defp dst_active?(%DateTime{month: month}) when month in [3, 4, 5, 6, 7, 8, 9, 10], do: true
  defp dst_active?(_), do: false

  # Parse datetime-local input value
  defp parse_datetime_local(nil), do: nil
  defp parse_datetime_local(""), do: nil

  defp parse_datetime_local(value) when is_binary(value) do
    case NaiveDateTime.from_iso8601(value <> ":00") do
      {:ok, naive} -> DateTime.from_naive!(naive, "Etc/UTC")
      _ -> nil
    end
  end
end
