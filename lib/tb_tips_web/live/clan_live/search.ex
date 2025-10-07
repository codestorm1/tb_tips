defmodule TbTipsWeb.ClanLive.Search do
  use TbTipsWeb, :live_view
  alias TbTips.Clans

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Search Clans")
     |> assign(:kingdom, "")
     |> assign(:abbr, "")
     |> assign(:name, "")
     |> assign(:results, [])
     |> assign(:searched, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-4 py-8">
      <.header>
        Find a Clan
        <:subtitle>Search by name, kingdom, or abbreviation</:subtitle>
      </.header>

      <div class="mt-8">
        <form phx-submit="search" class="mb-8">
          <div class="grid grid-cols-1 md:grid-cols-4 gap-3">
            <input
              type="text"
              name="kingdom"
              value={@kingdom}
              placeholder="Kingdom (e.g., 168)"
              class="px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            />
            <input
              type="text"
              name="abbr"
              value={@abbr}
              placeholder="Abbreviation (e.g., COC)"
              class="px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            />
            <input
              type="text"
              name="name"
              value={@name}
              placeholder="Clan name"
              class="px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            />
            <button
              type="submit"
              class="px-6 py-3 bg-blue-600 text-white font-semibold rounded-lg hover:bg-blue-700"
            >
              Search
            </button>
          </div>
        </form>

        <%= if @searched do %>
          <div class="mb-4 text-sm text-gray-600">
            <%= if @results == [] do %>
              No results
            <% end %>
          </div>

          <%= if @results == [] do %>
            <div class="text-center py-12 text-gray-500">
              <p class="text-lg">No clans found</p>
              <p class="mt-2">Try a different search or create your own clan</p>
              <.link navigate={~p"/clans/new"} class="mt-4 inline-block text-blue-600 hover:underline">
                Create New Clan
              </.link>
            </div>
          <% else %>
            <div class="space-y-4">
              <%= for clan <- @results do %>
                <div class="border rounded-lg p-6 hover:shadow-md transition">
                  <div class="flex items-start justify-between">
                    <div class="flex-1">
                      <h3 class="text-xl font-semibold text-gray-900">{clan.name}</h3>
                      <p class="text-gray-600 mt-1">
                        Kingdom {clan.kingdom} • {clan.abbr}
                      </p>
                    </div>
                    <.link
                      :if={Map.has_key?(clan, :invite_key) && clan.invite_key}
                      navigate={~p"/join/#{clan.invite_key}"}
                      class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                    >
                      Join Clan
                    </.link>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        <% else %>
          <div class="text-center py-12 text-gray-500">
            <p>Enter a clan name, kingdom (e.g. 160), or abbreviation (e.g. COC)</p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event(
        "search",
        %{"kingdom" => kingdom, "abbr" => abbr, "name" => name},
        socket
      ) do
    kingdom = String.trim(kingdom)
    abbr = String.trim(abbr) |> String.upcase()
    name = String.trim(name)

    results =
      if kingdom != "" || abbr != "" || name != "" do
        Clans.search_clans(kingdom, abbr, name)
      else
        []
      end

    {:noreply,
     socket
     |> assign(:kingdom, kingdom)
     |> assign(:abbr, abbr)
     |> assign(:name, name)
     |> assign(:results, results)
     |> assign(:searched, true)}
  end
end
