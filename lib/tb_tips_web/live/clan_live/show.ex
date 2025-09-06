defmodule TbTipsWeb.ClanLive.Show do
  use TbTipsWeb, :live_view

  alias TbTips.Clans

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Clan {@clan.id}
        <:subtitle>This is a clan record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/clans"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/clans/#{@clan.slug}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit clan
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@clan.name}</:item>
        <:item title="Slug">{@clan.slug}</:item>
        <:item title="Kingdom">{@clan.kingdom}</:item>
        <:item title="Admin key">{@clan.admin_key}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"clan_slug" => slug} = _params, _session, socket) do
    case Clans.get_clan_by_slug(slug) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Unknown clan.")
         # or ~p"/clans" if you have a clans index
         |> push_navigate(to: ~p"/")}

      clan ->
        socket =
          socket
          |> assign(:page_title, "Show Clan")
          |> assign(:clan, clan)
          |> assign(:clan, Clans.get_clan_by_slug!(slug))

        {:ok, socket}
    end
  end
end
