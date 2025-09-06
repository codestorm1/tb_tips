defmodule TbTipsWeb.EventLive.Show do
  use TbTipsWeb, :live_view

  alias TbTips.Events

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Event {@event.id}
        <:subtitle>This is a event record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/events"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/events/#{@event}/edit?return_to=show"}>
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
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Event")
     |> assign(:event, Events.get_event!(id))}
  end
end
