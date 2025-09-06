defmodule TbTipsWeb.EventLive.Form do
  use TbTipsWeb, :live_view

  alias TbTips.Events
  alias TbTips.Events.Event

  @impl true
  def mount(_params, _session, socket),
    do: {:ok, assign(socket, :user_tz, nil)}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="page" phx-hook="TzSender">
        <.header>
          {@page_title}
          <:subtitle>Create an event for {@clan.name}</:subtitle>
        </.header>

        <.form for={@form} id="event-form" phx-change="validate" phx-submit="save">
          <.input field={@form[:event_type]} type="text" label="Event type" />
          <.input field={@form[:start_time]} type="datetime-local" label="Start time" />

          <div class="mt-1 text-xs text-gray-600">
            Your Local Time — {tz_city(@user_tz)}
          </div>

          <.input field={@form[:description]} type="textarea" label="Description" />
          <.input field={@form[:created_by_name]} type="text" label="Your name" />
          <footer>
            <.button phx-disable-with="Saving..." variant="primary">Save Event</.button>
            <.button navigate={return_path(@return_to)}>Cancel</.button>
          </footer>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    event = Events.get_event!(id)

    # Verify event belongs to this clan
    if event.clan_id != socket.assigns.clan.id do
      socket
      |> put_flash(:error, "Event not found")
      |> redirect(to: ~p"/clans/#{socket.assigns.clan.slug}/events")
    else
      socket
      |> assign(:page_title, "Edit Event")
      |> assign(:event, event)
      |> assign(:form, to_form(Events.change_event(event)))
    end
  end

  defp apply_action(socket, :new, _params) do
    event = %Event{}

    socket
    |> assign(:page_title, "New Event")
    |> assign(:event, event)
    |> assign(:form, to_form(Events.change_event(event)))
  end

  @impl true
  def handle_event("validate", %{"event" => event_params}, socket) do
    changeset = Events.change_event(socket.assigns.event, event_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"event" => event_params}, socket) do
    save_event(socket, socket.assigns.live_action, event_params)
  end

  def handle_event("tz", %{"tz" => tz}, socket),
    do: {:noreply, assign(socket, :user_tz, tz)}

  defp save_event(socket, :edit, event_params) do
    case Events.update_event(socket.assigns.event, event_params) do
      {:ok, event} ->
        path =
          case socket.assigns.return_to do
            "show" -> ~p"/clans/#{socket.assigns.clan.slug}/events/#{event}"
            _ -> ~p"/clans/#{socket.assigns.clan.slug}/events"
          end

        {:noreply,
         socket
         |> put_flash(:info, "Event updated successfully")
         |> push_navigate(to: path)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_event(socket, :new, event_params) do
    # Auto-set the clan_id for new events
    event_params = Map.put(event_params, "clan_id", socket.assigns.clan.id)

    case Events.create_event(event_params) do
      {:ok, event} ->
        path =
          case socket.assigns.return_to do
            "show" -> ~p"/clans/#{socket.assigns.clan.slug}/events/#{event}"
            _ -> ~p"/clans/#{socket.assigns.clan.slug}/events"
          end

        {:noreply,
         socket
         |> put_flash(:info, "Event created successfully")
         |> push_navigate(to: path)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index") do
    # This is used for the Cancel button - we need to handle this differently
    # For now, just return to clans index
    ~p"/clans"
  end

  defp return_path("show") do
    ~p"/clans"
  end

  defp tz_city(nil), do: "Local"
  defp tz_city(""), do: "Local"

  defp tz_city(tz),
    do: tz |> String.split("/") |> List.last() |> String.replace("_", " ")
end
