defmodule TbTipsWeb.DashboardLive do
  use TbTipsWeb, :live_view

  alias TbTips.Events
  alias TbTips.ClanMemberships
  alias TbTips.Events

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    user_clans = ClanMemberships.list_user_clans(user.id)
    upcoming_events = Events.list_user_events(user.id)

    {:ok,
     socket
     |> assign(:page_title, "Dashboard")
     |> assign(:user_clans, user_clans)
     |> assign(:upcoming_events, upcoming_events)}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto px-4 py-8">
      <.header>
        Welcome back, {@current_scope.user.display_name}
        <:subtitle>Your clans and upcoming events</:subtitle>
      </.header>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mt-8">
        <!-- My Clans -->
        <div>
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-xl font-semibold">My Clans</h2>
            <.link navigate={~p"/clans/new"} class="btn btn-primary btn-sm">
              Create Clan
            </.link>
          </div>

          <%= if @user_clans == [] do %>
            <div class="text-center py-8 text-gray-500">
              <p>You haven't joined any clans yet.</p>
              <.link navigate={~p"/clans/search"} class="text-blue-600 hover:underline">
                Search for clans to join
              </.link>
            </div>
          <% else %>
            <div class="space-y-3">
              <%= for %{clan: clan, role: role} <- @user_clans do %>
                <div class="border rounded-lg p-4">
                  <div class="flex items-center justify-between">
                    <div>
                      <h3 class="font-medium">{clan.name}</h3>
                      <p class="text-sm text-gray-600">Kingdom {clan.kingdom}</p>
                      <span class="text-xs px-2 py-1 bg-blue-100 rounded">
                        {String.capitalize(to_string(role))}
                      </span>
                    </div>
                    <.link navigate={~p"/clans/#{clan.slug}/events"} class="btn btn-sm">
                      View Events
                    </.link>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
        
    <!-- Upcoming Events -->
        <div>
          <h2 class="text-xl font-semibold mb-4">Upcoming Events</h2>

          <%= if @upcoming_events == [] do %>
            <div class="text-center py-8 text-gray-500">
              <p>No upcoming events scheduled.</p>
            </div>
          <% else %>
            <div class="space-y-3">
              <%= for %{event: event, clan: clan} <- Enum.take(@upcoming_events, 5) do %>
                <div class="border rounded-lg p-4">
                  <div class="flex items-start justify-between">
                    <div>
                      <h4 class="font-medium">{event.event_type}</h4>
                      <p class="text-sm text-gray-600">{clan.name}</p>
                      <p class="text-xs text-gray-500">
                        {Calendar.strftime(event.start_time, "%m/%d %H:%M")}
                      </p>
                    </div>
                    <.link navigate={~p"/clans/#{clan.slug}/events/#{event.id}"} class="btn btn-sm">
                      View
                    </.link>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
