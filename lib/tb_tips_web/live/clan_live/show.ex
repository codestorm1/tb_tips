defmodule TbTipsWeb.ClanLive.Show do
  use TbTipsWeb, :live_view

  alias TbTips.Clans
  alias TbTips.Events
  import TbTipsWeb.TimeComponents

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case Clans.get_clan_by_slug(slug) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Clan not found")
         |> redirect(to: ~p"/")}

      clan ->
        events = Events.list_upcoming_events_for_clan(clan.id)

        {:ok,
         socket
         |> assign(:clan, clan)
         |> assign(:events, events)
         |> assign(:page_title, "#{clan.name} (#{clan.kingdom})")}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
