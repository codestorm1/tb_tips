defmodule TbTipsWeb.TimeDisplay do
  use Phoenix.Component

  @moduledoc false

  # Use either syntax:
  #   <.tb_time datetime={@event.start_time}/>
  #   <TbTipsWeb.TimeDisplay.tb_time datetime={@event.start_time} />
  #
  # Accepts %DateTime{} (any zone) or ISO8601 string.
  # Renders Reset time + local time, or "—" if nil/blank.

  attr :datetime, :any, required: true
  attr :class, :string, default: ""
  # optional small label
  attr :label, :string, default: nil

  def tb_time(assigns) do
    assigns =
      case normalize(assigns.datetime) do
        nil ->
          assign(assigns, :reset_time, nil)

        %DateTime{} = dt ->
          reset_offset = calculate_reset_offset(dt)
          reset_time = "Reset #{reset_offset}"
          assign(assigns, :reset_time, reset_time)
      end

    ~H"""
    <div class={@class}>
      <%= if @label do %>
        <span class="text-gray-500">{@label}</span>
      <% end %>
      <%= if @reset_time do %>
        <div class="space-y-1">
          <div class="text-sm font-medium text-blue-700">
            {@reset_time}
          </div>
          <div
            id={"local-time-#{System.unique_integer([:positive])}"}
            class="text-xs text-gray-600"
            phx-hook="LocalTime"
            data-utc={DateTime.to_iso8601(normalize(@datetime))}
          >
            Loading local time...
          </div>
        </div>
      <% else %>
        <span class="text-gray-400">—</span>
      <% end %>
    </div>
    """
  end

  @doc """
  Enhanced time display for event show pages
  """
  attr :datetime, :any, required: true
  attr :class, :string, default: ""

  def tb_time_detailed(assigns) do
    assigns =
      case normalize(assigns.datetime) do
        nil ->
          assign(assigns, :reset_time, nil)

        %DateTime{} = dt ->
          reset_offset = calculate_reset_offset(dt)
          reset_time = "Reset #{reset_offset}"
          assign(assigns, :reset_time, reset_time)
      end

    ~H"""
    <div class={[
      "bg-gradient-to-r from-blue-50 to-indigo-50 border border-blue-200 rounded-xl p-4",
      @class
    ]}>
      <%= if @reset_time do %>
        <!-- Reset Time -->
        <div class="flex items-center space-x-3 mb-3">
          <div class="bg-blue-500 text-white px-3 py-1 rounded-full text-sm font-semibold">
            {@reset_time}
          </div>
          <div class="text-blue-700 text-sm font-medium">Total Battle Time</div>
        </div>
        
    <!-- Local Time -->
        <div class="flex items-center space-x-3">
          <svg class="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
            >
            </path>
          </svg>
          <div>
            <div class="text-gray-600 text-xs uppercase tracking-wide font-medium">
              Your Local Time
            </div>
            <div
              id={"detailed-local-time-#{System.unique_integer([:positive])}"}
              class="text-lg font-semibold text-gray-900"
              phx-hook="LocalTime"
              data-utc={DateTime.to_iso8601(normalize(@datetime))}
            >
              Loading...
            </div>
          </div>
        </div>
        
    <!-- Countdown -->
        <div class="mt-4 pt-3 border-t border-blue-200">
          <div class="text-gray-600 text-xs uppercase tracking-wide font-medium mb-2">
            Time Until Event
          </div>
          <div
            id={"countdown-#{System.unique_integer([:positive])}"}
            class="text-orange-600 font-medium"
            phx-hook="EventCountdown"
            data-utc={DateTime.to_iso8601(normalize(@datetime))}
          >
            Calculating...
          </div>
        </div>
      <% else %>
        <div class="text-gray-400 text-center py-4">No time set</div>
      <% end %>
    </div>
    """
  end

  attr :day, :string, default: ""
  attr :reset_offset, :string, default: ""
  attr :class, :string, default: ""

  def time_preview(assigns) do
    ~H"""
    <div class={["space-y-3", @class]} id="time-preview" phx-hook="TimePreview">
      <!-- Reset Time -->
      <div class="bg-blue-50 border border-blue-200 rounded-lg p-3">
        <div class="text-sm font-medium text-blue-700 mb-1">
          Reset Time (R+<span id="reset-offset-display">{@reset_offset}</span>)
        </div>
        <div class="text-lg font-semibold text-blue-900" id="reset-time-display">
          Select day and time
        </div>
      </div>
      
    <!-- Local Time -->
      <div class="bg-green-50 border border-green-200 rounded-lg p-3">
        <div class="text-sm font-medium text-green-700 mb-1">Your Local Time</div>
        <div class="flex justify-between items-center">
          <span class="text-lg font-semibold text-green-900" id="local-time-display">
            Select day and time
          </span>
          <span class="text-sm text-green-600 bg-green-100 px-2 py-1 rounded" id="timezone-display">
            <!-- Timezone will appear here -->
          </span>
        </div>
      </div>
      
    <!-- Countdown -->
      <div class="bg-orange-50 border border-orange-200 rounded-lg p-3">
        <div class="text-sm font-medium text-orange-700 mb-2">Time Until Event</div>
        <div class="flex justify-center gap-3" id="countdown-display">
          <div class="text-center">
            <div class="text-xl font-bold text-orange-900" id="countdown-days">-</div>
            <div class="text-xs text-orange-600">Days</div>
          </div>
          <div class="text-center">
            <div class="text-xl font-bold text-orange-900" id="countdown-hours">-</div>
            <div class="text-xs text-orange-600">Hours</div>
          </div>
          <div class="text-center">
            <div class="text-xl font-bold text-orange-900" id="countdown-minutes">-</div>
            <div class="text-xs text-orange-600">Minutes</div>
          </div>
          <div class="text-center">
            <div class="text-xl font-bold text-orange-900" id="countdown-seconds">-</div>
            <div class="text-xs text-orange-600">Seconds</div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Simple time preview for datetime picker forms
  """
  attr :datetime, :any, required: true
  attr :class, :string, default: ""

  def time_preview_simple(assigns) do
    assigns =
      case normalize(assigns.datetime) do
        nil ->
          assign(assigns, :reset_time, nil)

        %DateTime{} = dt ->
          reset_offset = calculate_reset_offset(dt)
          reset_time = "Reset #{reset_offset}"
          assign(assigns, :reset_time, reset_time)

        %NaiveDateTime{} = ndt ->
          # Convert naive datetime to UTC for calculation
          case DateTime.from_naive(ndt, "Etc/UTC") do
            {:ok, dt} ->
              reset_offset = calculate_reset_offset(dt)
              reset_time = "Reset #{reset_offset}"
              assign(assigns, :reset_time, reset_time)

            _ ->
              assign(assigns, :reset_time, nil)
          end

        _ ->
          assign(assigns, :reset_time, nil)
      end

    ~H"""
    <%= if @reset_time do %>
      <div class={["bg-blue-50 border border-blue-200 rounded-lg p-3", @class]}>
        <div class="flex items-center justify-between">
          <div>
            <div class="text-sm font-medium text-blue-700">
              {@reset_time}
            </div>
            <div class="text-xs text-blue-600">Total Battle Time</div>
          </div>
          <div class="text-right">
            <div
              id={"preview-local-time-#{System.unique_integer([:positive])}"}
              class="text-sm font-medium text-gray-900"
              phx-hook="LocalTime"
              data-utc={format_for_js(@datetime)}
            >
              Loading...
            </div>
            <div class="text-xs text-gray-600">Your Local Time</div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  # ---- helpers ----

  # Format datetime for JavaScript consumption
  defp format_for_js(nil), do: ""
  defp format_for_js(""), do: ""
  defp format_for_js(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  defp format_for_js(%NaiveDateTime{} = ndt) do
    case DateTime.from_naive(ndt, "Etc/UTC") do
      {:ok, dt} -> DateTime.to_iso8601(dt)
      _ -> ""
    end
  end

  defp format_for_js(iso) when is_binary(iso), do: iso

  # Calculate hours after reset (18:00 UTC), keeping within ±12 hours
  defp calculate_reset_offset(%DateTime{} = datetime) do
    date = DateTime.to_date(datetime)

    case DateTime.new(date, ~T[18:00:00], "Etc/UTC") do
      {:ok, today_reset} ->
        # Calculate hours difference from today's reset
        diff_seconds = DateTime.diff(datetime, today_reset, :second)
        hours_diff = div(diff_seconds, 3600)

        cond do
          # If more than +12 hours, use next day's reset with negative offset
          hours_diff > 12 ->
            {:ok, tomorrow_reset} = DateTime.new(Date.add(date, 1), ~T[18:00:00], "Etc/UTC")
            new_diff = div(DateTime.diff(datetime, tomorrow_reset, :second), 3600)
            "#{new_diff}"

          # If less than -12 hours, use previous day's reset with positive offset
          hours_diff < -12 ->
            {:ok, yesterday_reset} = DateTime.new(Date.add(date, -1), ~T[18:00:00], "Etc/UTC")
            new_diff = div(DateTime.diff(datetime, yesterday_reset, :second), 3600)
            "+#{new_diff}"

          # Within ±12 hours, use as-is
          hours_diff >= 0 ->
            "+#{hours_diff}"

          true ->
            "#{hours_diff}"
        end

      _ ->
        "?"
    end
  end

  # Normalize to UTC DateTime (best-effort; no tzdata dependency)
  defp normalize(nil), do: nil
  defp normalize(""), do: nil

  defp normalize(%DateTime{time_zone: "Etc/UTC"} = dt), do: dt

  defp normalize(%DateTime{} = dt) do
    case DateTime.shift_zone(dt, "Etc/UTC") do
      {:ok, z} -> z
      # best-effort if no tzdb configured
      _ -> %{dt | time_zone: "Etc/UTC"}
    end
  end

  defp normalize(iso) when is_binary(iso) do
    case DateTime.from_iso8601(iso) do
      {:ok, dt, _} -> normalize(dt)
      _ -> nil
    end
  end
end
