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

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.input field={@form[:start_time]} type="datetime-local" label="Start Time (UTC)" />
        </div>

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

  # Helper function to format datetime for HTML datetime-local input
  #  defp format_datetime_local(nil), do: ""

  # defp format_datetime_local(%DateTime{} = datetime) do
  #   datetime
  #   |> DateTime.to_naive()
  #   |> NaiveDateTime.to_string()
  #   # "YYYY-MM-DDTHH:MM" format
  #   |> String.slice(0, 16)
  # end

  # Helper function to translate errors
  # defp translate_error({msg, opts}) do
  #   Enum.reduce(opts, msg, fn {key, value}, acc ->
  #     String.replace(acc, "%{#{key}}", to_string(value))
  #   end)
  # end
end
