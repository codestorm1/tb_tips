defmodule TbTipsWeb.DashboardLive do
  use TbTipsWeb, :live_view

  alias TbTips.Events

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    upcoming_events = Events.list_user_events(user.id)

    {:ok,
     socket
     |> assign(:page_title, "Dashboard")
     |> assign(:upcoming_events, upcoming_events)}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto px-4 py-8">
      <.header>
        Welcome back, {@current_scope.user.display_name}
        <:subtitle>Your upcoming battle events</:subtitle>
      </.header>

      <div class="mt-8">
        <%= if @upcoming_events == [] do %>
          <div class="text-center py-16 bg-gray-50 rounded-lg">
            <svg
              class="mx-auto h-12 w-12 text-gray-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
              />
            </svg>
            <h3 class="mt-2 text-lg font-medium text-gray-900">No upcoming events</h3>
            <p class="mt-1 text-sm text-gray-500">
              Get started by creating a clan or joining one.
            </p>
            <div class="mt-6 flex justify-center gap-4">
              <.link
                navigate={~p"/clans/new"}
                class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
              >
                Create Clan
              </.link>
              <.link
                navigate={~p"/clans"}
                class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
              >
                Browse Clans
              </.link>
            </div>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for %{event: event, clan: clan} <- @upcoming_events do %>
              <div class="border rounded-lg p-6 bg-white hover:shadow-lg transition-shadow">
                <div class="flex items-start justify-between gap-4">
                  <div class="flex-1 min-w-0">
                    <div class="flex items-center gap-3 mb-2">
                      <h3 class="text-xl font-bold text-gray-900">{event.event_type}</h3>
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                        {clan.name}
                      </span>
                    </div>

                    <div class="flex items-center gap-2 text-sm text-gray-600 mb-3">
                      <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
                        />
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
                        />
                      </svg>
                      <span>K{clan.kingdom}-{clan.abbr}</span>
                    </div>

                    <div class="space-y-2">
                      <div class="flex items-center gap-2 text-sm">
                        <svg
                          class="h-4 w-4 text-gray-400"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                          />
                        </svg>
                        <span class="text-gray-700">
                          {Calendar.strftime(event.start_time, "%a, %b %d at %I:%M %p")}
                        </span>
                      </div>

                      <%= if event.description do %>
                        <p class="text-sm text-gray-600 mt-2">{event.description}</p>
                      <% end %>
                    </div>
                  </div>

                  <.link
                    navigate={~p"/clans/#{clan.id}/events/#{event.id}"}
                    class="flex-shrink-0 px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                  >
                    View Details
                  </.link>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
