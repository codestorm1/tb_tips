defmodule TbTipsWeb.EventLive.FormComponent do
  use TbTipsWeb, :live_component

  alias TbTips.Events

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Schedule a new event for {@clan.name}</:subtitle>
      </.header>

      <.form
        for={@form}
        id="event-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:title]}
          type="text"
          label="Event Title"
          placeholder="e.g., Daily Tin Man 8PM"
        />

        <.input
          field={@form[:event_type]}
          type="select"
          label="Event Type"
          prompt="Choose an event type"
          options={Events.Event.event_types() |> Enum.map(&{&1, &1})}
        />

        <.input field={@form[:start_time]} type="datetime-local" label="Start Time (UTC)" />

        <.input
          field={@form[:description]}
          type="textarea"
          label="Description"
          placeholder="Additional details about the event..."
        />

        <.input
          field={@form[:created_by_name]}
          type="text"
          label="Your Name"
          placeholder="Who's creating this event?"
        />

        <div class="mt-6">
          <.button type="submit" phx-disable-with="Saving...">Save Event</.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{event: event, clan: _clan} = assigns, socket) do
    changeset = Events.change_event(event)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"event" => event_params}, socket) do
    changeset =
      socket.assigns.event
      |> Events.change_event(event_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("update_datetime", params, socket) do
    # Extract datetime components from the custom inputs
    datetime = build_datetime_from_params(params)

    # Update the form with the new datetime
    current_params = form_to_params(socket.assigns.form)
    updated_params = Map.put(current_params, "start_time", datetime)

    changeset =
      socket.assigns.event
      |> Events.change_event(updated_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"event" => event_params}, socket) do
    save_event(socket, socket.assigns.action, event_params)
  end

  defp save_event(socket, :edit, event_params) do
    case Events.update_event(socket.assigns.event, event_params) do
      {:ok, event} ->
        notify_parent({:saved, event})

        {:noreply,
         socket
         |> put_flash(:info, "Event updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_event(socket, :new, event_params) do
    # Add clan_id to the params
    event_params = Map.put(event_params, "clan_id", socket.assigns.clan.id)

    case Events.create_event(event_params) do
      {:ok, event} ->
        notify_parent({:saved, event})

        {:noreply,
         socket
         |> put_flash(:info, "Event created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  # Build datetime from custom input components
  defp build_datetime_from_params(params) do
    day = params["event_start_time_day"]
    reset_hours = params["event_start_time_reset"]

    if day && reset_hours do
      case Date.from_iso8601(day) do
        {:ok, date} ->
          # TB reset is at 8pm Cyprus time
          # Cyprus is UTC+2 (standard) or UTC+3 (DST)
          # So reset is at 6pm UTC (standard) or 5pm UTC (DST)

          # Simple DST check for Cyprus (rough approximation)
          utc_reset_hour =
            case date.month do
              # DST: 8pm Cyprus = 5pm UTC
              month when month in [4, 5, 6, 7, 8, 9] -> 17
              # Standard: 8pm Cyprus = 6pm UTC
              _ -> 18
            end

          # Create base datetime at reset time
          {:ok, reset_datetime} = DateTime.new(date, Time.new!(utc_reset_hour, 0, 0), "Etc/UTC")

          # Add the reset offset hours
          {offset_hours, _} = Integer.parse(reset_hours)
          final_datetime = DateTime.add(reset_datetime, offset_hours * 3600, :second)

          DateTime.to_iso8601(final_datetime)

        _ ->
          nil
      end
    else
      nil
    end
  end

  # Convert form to params for updating
  defp form_to_params(form) do
    Enum.reduce(form, %{}, fn {key, field}, acc ->
      Map.put(acc, Atom.to_string(key), field.value)
    end)
  end
end
