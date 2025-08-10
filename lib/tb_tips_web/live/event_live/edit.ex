defmodule TbTipsWeb.EventLive.Edit do
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
           |> assign(:page_title, "Edit Event - #{clan.name}")}
        end
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :action, :edit)}
  end

  @impl true
  def handle_info({TbTipsWeb.EventLive.FormComponent, {:saved, _event}}, socket) do
    {:noreply, socket}
  end
end
