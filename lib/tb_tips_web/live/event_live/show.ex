defmodule TbTipsWeb.EventLive.Show do
  use TbTipsWeb, :live_view

  alias TbTips.Events
  alias TbTips.Clans

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Event {@event.id}
        <:subtitle>This is a event record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/clans/#{@clan.slug}/events"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button
            variant="primary"
            navigate={~p"/clans/#{@clan.slug}/events/#{@event}/edit?return_to=show"}
          >
            <.icon name="hero-pencil-square" /> Edit event
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Description">{@event.description}</:item>
        <:item title="Start time">{@event.start_time}</:item>
        <:item title="Event type">{@event.event_type}</:item>
        <:item title="Created by name">{@event.created_by_name}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"clan_slug" => slug, "id" => id}, _session, socket) do
    case Clans.get_clan_by_slug(slug) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Clan not found")
         |> redirect(to: ~p"/clans")}

      clan ->
        event = Events.get_event!(id)

        # Verify event belongs to this clan
        if event.clan_id != clan.id do
          {:ok,
           socket
           |> put_flash(:error, "Event not found")
           |> redirect(to: ~p"/clans/#{clan.slug}/events")}
        else
          {:ok,
           socket
           |> assign(:page_title, "#{event.event_type} - #{clan.name}")
           |> assign(:clan, clan)
           |> assign(:event, event)}
        end
    end
  end
end
