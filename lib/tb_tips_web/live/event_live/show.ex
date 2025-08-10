defmodule TbTipsWeb.EventLive.Show do
  use TbTipsWeb, :live_view

  alias TbTips.Clans
  alias TbTips.Events

  @impl true
  def mount(%{"clan_slug" => slug, "id" => id}, _session, socket) do
    case Clans.get_clan_by_slug(slug) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Clan not found")
         |> redirect(to: ~p"/")}

      clan ->
        event = Events.get_event!(id)

        # Verify event belongs to this clan
        if event.clan_id != clan.id do
          {:ok,
           socket
           |> put_flash(:error, "Event not found")
           |> redirect(to: ~p"/clans/#{clan.slug}")}
        else
          {:ok,
           socket
           |> assign(:clan, clan)
           |> assign(:event, event)
           |> assign(:page_title, "#{event.title} - #{clan.name}")}
        end
    end
  end

  @impl true
  def handle_event("delete", _params, socket) do
    {:ok, _} = Events.delete_event(socket.assigns.event)

    {:noreply,
     socket
     |> put_flash(:info, "Event deleted successfully")
     |> push_navigate(to: ~p"/clans/#{socket.assigns.clan.slug}/events")}
  end
end
