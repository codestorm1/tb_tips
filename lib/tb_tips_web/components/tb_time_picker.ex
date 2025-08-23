defmodule TbTipsWeb.TbTimePicker do
  use Phoenix.LiveComponent

  @impl true
  def render(assigns) do
    IO.inspect(assigns.datetime, label: "TbTimePicker datetime assign")
    IO.inspect(assigns.value, label: "TbTimePicker value assign")

    ~H"""
    <div class="space-y-4">
      <label class="block text-sm font-medium text-gray-700">{@label}</label>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <!-- Day Selection -->
        <div>
          <label class="block text-xs font-medium text-gray-500 mb-1">Day</label>
          <select
            name="day"
            value={@selected_day}
            phx-change="day_changed"
            phx-target={@myself}
            class="w-full select"
          >
            <option value="">Choose day</option>
            <%= for {date, label} <- upcoming_days() do %>
              <option value={date} selected={@selected_day == date}>
                {label}
              </option>
            <% end %>
          </select>
        </div>
        
    <!-- Reset Hours -->
        <div>
          <label class="block text-xs font-medium text-gray-500 mb-1">Reset Time</label>
          <select
            name="reset"
            value={@selected_reset}
            phx-change="reset_changed"
            phx-target={@myself}
            class="w-full select"
          >
            <option value="">Reset +?</option>
            <%= for hour <- -12..11 do %>
              <option value={hour} selected={@selected_reset == to_string(hour)}>
                Reset {if hour >= 0, do: "+#{hour}", else: "#{hour}"}
              </option>
            <% end %>
          </select>
        </div>
      </div>
      
    <!-- Preview -->
      <%= if @datetime do %>
        <div class="p-3 bg-blue-50 rounded-lg">
          <div class="text-sm font-medium text-blue-900">This will be at:</div>
          <div
            class="text-lg font-semibold text-blue-800"
            id={"preview-#{@id}"}
            phx-hook="LocalTime"
            data-utc={DateTime.to_iso8601(@datetime)}
          >
            Loading local time...
          </div>
        </div>
      <% end %>
      
    <!-- Hidden field with the actual datetime value -->
      <input type="hidden" name={@field} value={format_datetime(@datetime)} />
      
    <!-- Show validation errors -->
      <%= if @errors != [] do %>
        <div class="mt-2 text-sm text-red-600">
          <%= for error <- @errors do %>
            <p class="flex items-center">
              <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                <path
                  fill-rule="evenodd"
                  d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z"
                  clip-rule="evenodd"
                >
                </path>
              </svg>
              {error}
            </p>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    IO.inspect(assigns[:value], label: "TbTimePicker received value")
    IO.inspect(assigns[:errors], label: "TbTimePicker received errors")

    # Parse the value properly - don't just assign it directly
    datetime =
      case assigns[:value] do
        nil ->
          nil

        # Empty string should be nil, not ""
        "" ->
          nil

        value when is_binary(value) ->
          case DateTime.from_iso8601(value) do
            {:ok, dt, _} -> dt
            _ -> nil
          end

        %DateTime{} = dt ->
          dt

        _ ->
          nil
      end

    {day, reset} =
      if datetime do
        extract_day_and_reset(datetime)
      else
        {"", ""}
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:selected_day, day)
     |> assign(:selected_reset, reset)
     # Now this will be nil instead of ""
     |> assign(:datetime, datetime)
     |> assign(:errors, assigns[:errors] || [])}
  end

  @impl true
  def handle_event("day_changed", %{"value" => day}, socket) do
    socket = assign(socket, :selected_day, day)

    # Only build datetime and send message if BOTH day and reset are selected
    if day != "" and socket.assigns.selected_reset != "" do
      datetime = build_datetime(day, socket.assigns.selected_reset)

      if datetime do
        socket = assign(socket, :datetime, datetime)
        send(self(), {:datetime_changed, socket.assigns.field, datetime})
        {:noreply, socket}
      else
        {:noreply, assign(socket, :datetime, nil)}
      end
    else
      {:noreply, assign(socket, :datetime, nil)}
    end
  end

  def handle_event("reset_changed", %{"value" => reset}, socket) do
    socket = assign(socket, :selected_reset, reset)

    # Only build datetime and send message if BOTH day and reset are selected
    if reset != "" and socket.assigns.selected_day != "" do
      datetime = build_datetime(socket.assigns.selected_day, reset)

      if datetime do
        socket = assign(socket, :datetime, datetime)
        send(self(), {:datetime_changed, socket.assigns.field, datetime})
        {:noreply, socket}
      else
        {:noreply, assign(socket, :datetime, nil)}
      end
    else
      {:noreply, assign(socket, :datetime, nil)}
    end
  end

  # Build datetime from day and reset selections
  defp build_datetime(day, reset) when day != "" and reset != "" do
    case {Date.from_iso8601(day), Integer.parse(reset)} do
      {{:ok, date}, {reset_hours, ""}} ->
        # TB reset calculation
        utc_reset_hour =
          case date.month do
            # DST
            month when month in [4, 5, 6, 7, 8, 9] -> 17
            # Standard
            _ -> 18
          end

        with {:ok, reset_datetime} <-
               DateTime.new(date, Time.new!(utc_reset_hour, 0, 0), "Etc/UTC") do
          DateTime.add(reset_datetime, reset_hours * 3600, :second)
        else
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp build_datetime(_, _), do: nil

  # Extract day and reset from existing datetime
  defp extract_day_and_reset(%DateTime{} = datetime) do
    # Convert to Cyprus time to find the day and calculate reset offset
    case DateTime.shift_zone(datetime, "Asia/Nicosia") do
      {:ok, cyprus_time} ->
        day = Date.to_iso8601(DateTime.to_date(cyprus_time))

        # Calculate reset offset (simplified)
        reset_time = %{cyprus_time | hour: 20, minute: 0, second: 0, microsecond: {0, 0}}
        diff_hours = div(DateTime.diff(cyprus_time, reset_time, :second), 3600)

        {day, to_string(diff_hours)}

      _ ->
        {"", ""}
    end
  end

  defp extract_day_and_reset(_), do: {"", ""}

  # Format datetime for the hidden input
  defp format_datetime(nil), do: ""
  defp format_datetime(""), do: ""

  defp format_datetime(%DateTime{} = dt) do
    DateTime.to_iso8601(dt)
  end

  # Get upcoming days
  defp upcoming_days do
    today = Date.utc_today()

    for i <- 0..13 do
      date = Date.add(today, i)

      label =
        case i do
          0 -> "Today (#{Calendar.strftime(date, "%a %b %d")})"
          1 -> "Tomorrow (#{Calendar.strftime(date, "%a %b %d")})"
          _ -> Calendar.strftime(date, "%a %b %d")
        end

      {Date.to_iso8601(date), label}
    end
  end
end
