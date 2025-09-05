defmodule TbTipsWeb.EventLive.FormComponent do
  use TbTipsWeb, :live_component
  alias TbTips.Events

  ## RENDER

  def render(assigns) do
    ~H"""
    <div id="event-form-container">
      <.header>
        {@title}
        <:subtitle>Schedule a new event for {@clan.name}</:subtitle>
      </.header>

      <.form
        for={@form}
        id="event-form"
        phx-target={@myself}
        phx-submit="save"
      >
        
    <!-- Event Type -->
        <.input
          field={@form[:event_type]}
          type="select"
          label="Event Type *"
          prompt="Choose an event type"
          options={Events.Event.event_types() |> Enum.map(&{&1, &1})}
          required
        />
        
    <!-- Time Selection with JavaScript -->
        <div class="space-y-4 mt-4">
          <label class="block text-sm font-medium text-gray-700">Event Time *</label>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <!-- Day Selection -->
            <div>
              <label class="block text-xs font-medium text-gray-500 mb-1">Day</label>
              <select id="day-select" class="w-full select">
                <option value="">Choose day</option>
                <!-- Options populated by JavaScript -->
              </select>
            </div>
            
    <!-- Hour Selection -->
            <div>
              <label class="block text-xs font-medium text-gray-500 mb-1">Your Local Time</label>
              <select id="hour-select" class="w-full select">
                <option value="">Choose time</option>
                <%= for hour <- 0..23 do %>
                  <option value={hour}>{format_hour(hour)}</option>
                <% end %>
              </select>
            </div>
          </div>
          
    <!-- Hidden field that gets populated by JavaScript -->
          <input type="hidden" name="event[start_time]" id="computed-datetime" />
          
    <!-- Preview area -->
          <div id="time-preview" class="hidden mt-4 bg-blue-50 border border-blue-200 rounded-lg p-3">
            <div class="flex justify-between items-center">
              <div>
                <div class="text-sm font-medium text-blue-700" id="reset-display">
                  <!-- Reset time goes here -->
                </div>
                <div class="text-xs text-blue-600">Total Battle Time</div>
              </div>
              <div class="text-right">
                <div class="text-sm font-medium text-gray-900" id="local-display">
                  <!-- Local time display goes here -->
                </div>
                <div class="text-xs text-gray-600">Your Local Time</div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Description -->
        <.input field={@form[:description]} type="textarea" label="Description (optional)" />
        
    <!-- Name -->
        <.input field={@form[:created_by_name]} type="text" label="Your Name *" required />

        <div class="mt-6">
          <.button type="submit" phx-disable-with="Saving...">Save Event</.button>
        </div>
      </.form>

      <script>
        // Wait for DOM to be ready
        document.addEventListener('DOMContentLoaded', function() {
          initializeDropdowns();
        });

        // Also run immediately in case DOM is already ready
        if (document.readyState === 'loading') {
          document.addEventListener('DOMContentLoaded', initializeDropdowns);
        } else {
          initializeDropdowns();
        }

        function initializeDropdowns() {
          console.log('Initializing dropdowns...');

          let selectedDay = '';
          let selectedHour = '';

          // Get elements
          const daySelect = document.getElementById('day-select');
          const hourSelect = document.getElementById('hour-select');

          console.log('daySelect:', daySelect);
          console.log('hourSelect:', hourSelect);

          if (!daySelect || !hourSelect) {
            console.error('Could not find dropdown elements');
            return;
          }

          // Populate day options using user's local timezone
          function populateDayOptions() {
            console.log('Populating day options...');
            const today = new Date();

            // Clear existing options except the first one
            while (daySelect.children.length > 1) {
              daySelect.removeChild(daySelect.lastChild);
            }

            for (let i = 0; i < 14; i++) {
              const date = new Date(today);
              date.setDate(today.getDate() + i);

              const dateString = date.toISOString().split('T')[0]; // YYYY-MM-DD
              const dayName = date.toLocaleDateString('en-US', { weekday: 'short' });
              const monthName = date.toLocaleDateString('en-US', { month: 'short' });
              const dayNum = date.getDate();

              let label;
              if (i === 0) {
                label = `Today (${dayName} ${monthName} ${dayNum})`;
              } else if (i === 1) {
                label = `Tomorrow (${dayName} ${monthName} ${dayNum})`;
              } else {
                label = `${dayName} ${monthName} ${dayNum}`;
              }

              const option = document.createElement('option');
              option.value = dateString;
              option.textContent = label;
              daySelect.appendChild(option);
            }
            console.log('Day options populated:', daySelect.children.length);
          }

          function updateDateTime() {
            const daySelect = document.getElementById('day-select');
            const hourSelect = document.getElementById('hour-select');
            const hiddenInput = document.getElementById('computed-datetime');
            const preview = document.getElementById('time-preview');
            const resetDisplay = document.getElementById('reset-display');
            const localDisplay = document.getElementById('local-display');

            if (!selectedDay || selectedHour === '') {
              preview.classList.add('hidden');
              hiddenInput.value = '';
              return;
            }

            // Build LOCAL datetime first (what the user actually selected)
            const localDate = new Date(selectedDay + 'T' + String(selectedHour).padStart(2, '0') + ':00:00');

            // Convert to UTC for storage
            const utcDate = new Date(localDate.getTime() - (localDate.getTimezoneOffset() * 60000));
            const utcString = utcDate.toISOString();

            // Set the hidden field with UTC time
            hiddenInput.value = utcString;

            // Calculate reset offset using UTC time
            const resetHour = 18; // Reset at 18:00 UTC
            const todayResetUTC = new Date(utcDate);
            todayResetUTC.setUTCHours(resetHour, 0, 0, 0);

            let diffHours = Math.floor((utcDate - todayResetUTC) / (1000 * 60 * 60));

            // Keep within ±12 hours
            if (diffHours > 12) {
              const tomorrowReset = new Date(todayResetUTC);
              tomorrowReset.setUTCDate(tomorrowReset.getUTCDate() + 1);
              diffHours = Math.floor((utcDate - tomorrowReset) / (1000 * 60 * 60));
            } else if (diffHours < -12) {
              const yesterdayReset = new Date(todayResetUTC);
              yesterdayReset.setUTCDate(yesterdayReset.getUTCDate() - 1);
              diffHours = Math.floor((utcDate - yesterdayReset) / (1000 * 60 * 60));
            }

            const resetText = diffHours >= 0 ? `Reset +${diffHours}` : `Reset ${diffHours}`;
            resetDisplay.textContent = resetText;

            // Display the LOCAL time (what the user actually selected)
            const localOptions = {
              weekday: 'short',
              month: 'short',
              day: 'numeric',
              hour: 'numeric',
              minute: '2-digit'
            };
            localDisplay.textContent = localDate.toLocaleDateString('en-US', localOptions);

            // Show preview
            preview.classList.remove('hidden');
          }

          function formatHour(hour) {
            if (hour === 0) return "12:00 AM (Midnight)";
            if (hour < 12) return `${hour}:00 AM`;
            if (hour === 12) return "12:00 PM (Noon)";
            return `${hour - 12}:00 PM`;
          }

          // Set up event listeners
          daySelect.addEventListener('change', function() {
            selectedDay = this.value;
            updateDateTime();
          });

          hourSelect.addEventListener('change', function() {
            selectedHour = this.value;
            updateDateTime();
          });

          // Initialize from existing values if editing
          const hiddenInput = document.getElementById('computed-datetime');
          if (hiddenInput && hiddenInput.value) {
            // Parse existing datetime and set dropdowns
            const existingDate = new Date(hiddenInput.value);
            const dateString = existingDate.toISOString().split('T')[0];
            const hour = existingDate.getUTCHours();

            daySelect.value = dateString;
            hourSelect.value = hour;
            selectedDay = dateString;
            selectedHour = hour;
            updateDateTime();
          }

          // Populate day options using user's local date
          populateDayOptions();
        }
      </script>
    </div>
    """
  end

  ## LIFECYCLE

  def update(%{event: event} = assigns, socket) do
    changeset = Events.change_event(event)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))}
  end

  ## EVENTS

  def handle_event("save", %{"event" => event_params}, socket) do
    event_params = Map.put(event_params, "clan_id", socket.assigns.clan.id)
    save_event(socket, socket.assigns.action, event_params)
  end

  ## HELPERS

  defp day_options do
    # Use local date instead of UTC
    today = Date.utc_now() |> DateTime.to_date()

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

  defp format_hour(hour) do
    case hour do
      0 -> "12:00 AM (Midnight)"
      h when h < 12 -> "#{h}:00 AM"
      12 -> "12:00 PM (Noon)"
      h -> "#{h - 12}:00 PM"
    end
  end

  ## SAVE

  defp save_event(socket, action, event_params) do
    result =
      case action do
        # Just params, not (event, params)
        :new -> Events.create_event(event_params)
        :edit -> Events.update_event(socket.assigns.event, event_params)
      end

    case result do
      {:ok, event} ->
        notify_parent({:saved, event})
        {:noreply, socket |> put_flash(:info, "Event saved successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
