defmodule TbTipsWeb.EventLive.Form do
  use TbTipsWeb, :live_view

  alias TbTips.{Events, Clans}
  alias TbTips.Events.Event

  @impl true
  def mount(params, _session, socket) do
    # Always have a default so first render never blows up
    socket = assign_new(socket, :user_tz, fn -> nil end)

    clan = Clans.get_clan_by_slug!(params["clan_slug"])

    {event, changeset, page_title, live_action} =
      case params do
        %{"id" => id} ->
          ev = Events.get_event!(id)
          {ev, Events.change_event(ev), "Edit Event", :edit}

        _ ->
          ev = %Event{clan_id: clan.id}
          {ev, Events.change_event(ev), "New Event", :new}
      end

    {:ok,
     socket
     |> assign(:clan, clan)
     |> assign(:event, event)
     |> assign(:form, to_form(changeset))
     |> assign(:page_title, page_title)
     |> assign(:live_action, live_action)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="event-form-page" phx-hook="TzSender">
        <.header>
          {@page_title}
          <:subtitle>for {@clan.name}</:subtitle>
          <:actions>
            <.button navigate={~p"/clans/#{@clan.slug}/events"}>
              <.icon name="hero-arrow-left" /> Back
            </.button>
          </:actions>
        </.header>

        <.form for={@form} id="event-form" phx-change="validate" phx-submit="save" class="space-y-4">
          <.input field={@form[:event_type]} type="text" label="Event type" />
          <.input field={@form[:description]} type="textarea" label="Description" />
          <.input field={@form[:created_by_name]} type="text" label="Your name" />

          <.input field={@form[:start_time]} type="datetime-local" label="Start time" />
          <div class="mt-1 text-xs text-gray-600">
            Your Local Time<%= if city = tz_city(@user_tz) do %>
              — {city}
            <% end %>
          </div>

          <footer class="mt-4 flex gap-2">
            <.button variant="primary" phx-disable-with="Saving...">
              <.icon name="hero-check" /> Save Event
            </.button>
            <.button navigate={~p"/clans/#{@clan.slug}/events"} type="button">
              Cancel
            </.button>
          </footer>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  # ---- Events

  @impl true
  def handle_event("tz", %{"tz" => tz}, socket) do
    {:noreply, assign(socket, :user_tz, tz)}
  end

  @impl true
  def handle_event("validate", %{"event" => params}, socket) do
    changeset =
      socket.assigns.event
      |> Events.change_event(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"event" => params}, socket) do
    case socket.assigns.live_action do
      :edit ->
        case Events.update_event(socket.assigns.event, params) do
          {:ok, ev} ->
            {:noreply,
             socket
             |> put_flash(:info, "Event updated")
             |> assign(:event, ev)
             |> push_navigate(to: ~p"/clans/#{socket.assigns.clan.slug}/events")}

          {:error, cs} ->
            {:noreply, assign(socket, :form, to_form(cs))}
        end

      :new ->
        params = Map.put(params, "clan_id", socket.assigns.clan.id)

        case Events.create_event(params) do
          {:ok, _ev} ->
            {:noreply,
             socket
             |> put_flash(:info, "Event created")
             |> push_navigate(to: ~p"/clans/#{socket.assigns.clan.slug}/events")}

          {:error, cs} ->
            {:noreply, assign(socket, :form, to_form(cs))}
        end
    end
  end

  # ---- Helpers

  # turns "America/Los_Angeles" into "Los Angeles"; returns nil when unknown
  defp tz_city(nil), do: nil
  defp tz_city(""), do: nil

  defp tz_city(tz),
    do: tz |> String.split("/") |> List.last() |> String.replace("_", " ")
end
