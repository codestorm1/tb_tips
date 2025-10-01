defmodule TbTipsWeb.ClanLive.Index do
  use TbTipsWeb, :live_view

  alias TbTips.Clans

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Clans
        <:actions>
          <.button variant="primary" navigate={~p"/clans/new"}>
            <.icon name="hero-plus" /> New Clan
          </.button>
        </:actions>
      </.header>

      <.table
        id="clans"
        rows={@streams.clans}
        row_click={fn {_id, clan} -> JS.navigate(~p"/clans/#{clan.id}/") end}
      >
        <:col :let={{_id, clan}} label="Name">{clan.name}</:col>
        <:col :let={{_id, clan}} label="Kingdom">{clan.kingdom}</:col>
        <:col :let={{_id, clan}} label="Invite key">{clan.invite_key}</:col>
        <:action :let={{_id, clan}}>
          <div class="sr-only">
            <.link navigate={~p"/clans/#{clan.id}/"}>Show</.link>
          </div>
          <.link navigate={~p"/clans/#{clan.id}//edit"}>Edit</.link>
        </:action>
        <:action :let={{id, clan}}>
          <.link
            phx-click={JS.push("delete", value: %{id: clan.id}) |> hide("##{id}")}
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
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Clans")
     |> stream(:clans, list_clans())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    clan = Clans.get_clan!(id)
    {:ok, _} = Clans.delete_clan(clan)

    {:noreply, stream_delete(socket, :clans, clan)}
  end

  defp list_clans() do
    Clans.list_clans()
  end
end
