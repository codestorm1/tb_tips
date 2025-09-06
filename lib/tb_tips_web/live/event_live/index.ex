defmodule TbTipsWeb.EventLive.Index do
  use TbTipsWeb, :live_view

  alias TbTips.{Events, Clans}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@clan.name} Events
        <:subtitle>Kingdom {@clan.kingdom}</:subtitle>
        <:actions>
          <.button variant="primary" navigate={~p"/clans/#{@clan.slug}/events/new"}>
            <.icon name="hero-plus" /> New Event
          </.button>
          <.button navigate={~p"/clans/#{@clan.slug}"}>
            <.icon name="hero-arrow-left" /> Back to Clan
          </.button>
        </:actions>
      </.header>

      <.table
        id="events"
        rows={@streams.events}
        row_click={fn {_id, event} -> JS.navigate(~p"/clans/#{@clan.slug}/events/#{event}") end}
      >
        <:col :let={{_id, event}} label="Event Type">{event.event_type}</:col>
        <:col :let={{_id, event}} label="When">
          <TbTipsWeb.TimeDisplay.tb_time datetime={event.start_time} />
        </:col>
        <:col :let={{_id, event}} label="Created By">{event.created_by_name}</:col>
        <:col :let={{_id, event}} label="Description">{event.description}</:col>
        <:action :let={{_id, event}}>
          <div class="sr-only">
            <.link navigate={~p"/clans/#{@clan.slug}/events/#{event}"}>Show</.link>
          </div>
          <.link navigate={~p"/clans/#{@clan.slug}/events/#{event}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, event}}>
          <.link
            phx-click={JS.push("delete", value: %{id: event.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"clan_slug" => slug}, _session, socket) do
    case Clans.get_clan_by_slug(slug) do
      nil ->
        {:ok,
         socket
         |> assign(:user_tz, nil)
         |> put_flash(:error, "Clan not found")
         |> redirect(to: ~p"/clans")}

      clan ->
        {:ok,
         socket
         |> assign(:user_tz, nil)
         |> assign(:page_title, "#{clan.name} Events")
         |> assign(:clan, clan)
         |> stream(:events, Events.list_events_for_clan(clan.id))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    event = Events.get_event!(id)

    # Verify event belongs to this clan
    if event.clan_id == socket.assigns.clan.id do
      {:ok, _} = Events.delete_event(event)
      {:noreply, stream_delete(socket, :events, event)}
    else
      {:noreply, put_flash(socket, :error, "Cannot delete event from another clan")}
    end
  end
end
