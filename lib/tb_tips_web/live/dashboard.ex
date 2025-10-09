defmodule TbTipsWeb.DashboardLive do
  use TbTipsWeb, :live_view

  alias TbTips.Events

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    upcoming_events = Events.list_user_events(user.id)
    user_clans = TbTips.ClanMemberships.list_user_clans(user.id)

    {:ok,
     socket
     |> assign(:page_title, "Dashboard")
     |> assign(:upcoming_events, upcoming_events)
     |> assign(:user_clans, user_clans)}
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
          <%= if @user_clans == [] do %>
            <!-- No clans at all - show join options -->
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
              <p class="mt-1 text-sm text-gray-500 mb-6">
                Get started by creating a clan, searching for one, or using an invite key.
              </p>
              
    <!-- Invite Key Input -->
              <div class="max-w-sm mx-auto mb-8">
                <form action="/join-redirect" method="post" class="flex gap-2">
                  <input
                    type="hidden"
                    name="_csrf_token"
                    value={Plug.CSRFProtection.get_csrf_token()}
                  />
                  <input
                    type="text"
                    name="invite_key"
                    placeholder="Enter invite key"
                    autocomplete="off"
                    required
                    class="flex-1 px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent uppercase text-sm"
                  />
                  <button
                    type="submit"
                    class="px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700"
                  >
                    Join
                  </button>
                </form>
              </div>

              <div class="flex justify-center gap-4">
                <.link
                  navigate={~p"/clans/new"}
                  class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
                >
                  Create Clan
                </.link>
                <.link
                  navigate={~p"/clans/search"}
                  class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                >
                  Search Clans
                </.link>
              </div>
            </div>
          <% else %>
            <!-- Has clans but no events -->
            <div class="text-center py-12 bg-gray-50 rounded-lg">
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
              <p class="mt-1 text-sm text-gray-500 mb-6">
                Your clans don't have any events scheduled yet.
              </p>
              
    <!-- Show user's clans -->
              <div class="max-w-md mx-auto mb-6">
                <h4 class="text-sm font-medium text-gray-700 mb-3">Your Clans</h4>
                <div class="space-y-2">
                  <%= for %{clan: clan, role: role} <- @user_clans do %>
                    <.link
                      navigate={~p"/clans/#{clan.id}/events"}
                      class="block p-3 border rounded-lg hover:bg-white hover:shadow-sm transition text-left"
                    >
                      <div class="flex items-center justify-between">
                        <div>
                          <div class="font-medium text-gray-900">{clan.name}</div>
                          <div class="text-sm text-gray-600">K{clan.kingdom}-{clan.abbr}</div>
                        </div>
                        <span class="text-xs px-2 py-1 bg-gray-100 rounded-full text-gray-600">
                          {String.capitalize(to_string(role))}
                        </span>
                      </div>
                    </.link>
                  <% end %>
                </div>
              </div>

              <%= if Enum.any?(@user_clans, fn %{role: role} -> role in [:admin, :editor] end) do %>
                <p class="text-sm text-gray-600 mb-4">
                  You can create events for your clans to get started.
                </p>
              <% end %>
            </div>
          <% end %>
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
                        <TbTipsWeb.TimeDisplay.tb_time datetime={event.start_time} />
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
