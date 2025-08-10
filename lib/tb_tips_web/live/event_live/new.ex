defmodule TbTipsWeb.EventLive.New do
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
        {:ok,
         socket
         |> assign(:clan, clan)
         |> assign(:page_title, "New Event - #{clan.name}")}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(:event, %Events.Event{})
     |> assign(:action, :new)}
  end

  @impl true
  def handle_info({TbTipsWeb.EventLive.FormComponent, {:saved, _event}}, socket) do
    {:noreply, socket}
  end
end
