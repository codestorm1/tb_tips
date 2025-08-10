defmodule TbTipsWeb.EventLive.Index do
  use TbTipsWeb, :live_view

  alias TbTips.Clans
  alias TbTips.Events

  @impl true
  def mount(%{"clan_slug" => slug}, _session, socket) do
    case Clans.get_clan_by_slug(slug) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Clan not found")
         |> redirect(to: ~p"/")}

      clan ->
        events = Events.list_events_for_clan(clan.id)

        {:ok,
         socket
         |> assign(:clan, clan)
         |> assign(:events, events)
         |> assign(:page_title, "#{clan.name} Events")}
    end
  end
end
