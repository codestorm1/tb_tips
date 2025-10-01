# lib/tb_tips_web/live/clan_live/join.ex

defmodule TbTipsWeb.ClanLive.Join do
  use TbTipsWeb, :live_view
  alias TbTips.{Clans, ClanMemberships}

  def mount(%{"invite_key" => invite_key}, _session, socket) do
    case Clans.get_clan_by_invite_key(invite_key) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Invalid invite link")
         |> redirect(to: ~p"/")}

      clan ->
        user =
          case socket.assigns.current_scope do
            %{user: user} -> user
            _ -> nil
          end

        cond do
          # User not logged in - show registration options
          is_nil(user) ->
            {:ok,
             socket
             |> assign(:clan, clan)
             |> assign(:invite_key, invite_key)
             |> assign(:show_registration, true)}

          # User already a member
          ClanMemberships.get_clan_membership(user.id, clan.id) ->
            {:ok,
             socket
             |> put_flash(:info, "You're already a member of #{clan.name}")
             |> redirect(to: ~p"/clans/#{clan.id}/")}

          # User logged in but not a member - show join confirmation
          true ->
            {:ok,
             socket
             |> assign(:clan, clan)
             |> assign(:invite_key, invite_key)
             |> assign(:show_registration, false)}
        end
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto mt-8">
      <div class="bg-white p-6 rounded-lg shadow-md">
        <div class="text-center mb-6">
          <h1 class="text-2xl font-bold text-gray-900">Join Clan</h1>
          <h2 class="text-xl text-gray-700 mt-2">{@clan.name}</h2>
          <p class="text-gray-600">Kingdom {@clan.kingdom}</p>
        </div>

        <%= if @show_registration do %>
          <!-- Show this for logged-out users -->
          <div class="space-y-4">
            <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
              <p class="text-sm text-blue-700">
                You've been invited to join <strong>{@clan.name}</strong> in Total Battle.
                Create an account or log in to join!
              </p>
            </div>

            <div class="space-y-3">
              <.link
                href={~p"/users/register"}
                class="w-full bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 transition text-center block"
              >
                Create Account
              </.link>

              <.link
                href={~p"/users/log-in"}
                class="w-full bg-gray-100 text-gray-700 px-4 py-2 rounded-md hover:bg-gray-200 transition text-center block"
              >
                Log In
              </.link>
            </div>

            <div class="mt-4 text-xs text-gray-500 text-center">
              After creating an account or logging in, return to this link to join {@clan.name}
            </div>
          </div>
        <% else %>
          <!-- Show this for logged-in users -->
          <div class="space-y-4">
            <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
              <p class="text-sm text-blue-700 mb-2">
                You've been invited to join <strong>{@clan.name}</strong>
              </p>
              <p class="text-xs text-gray-600">
                As a member, you'll be able to view clan events and coordinate with other players.
                Clan leaders can promote you to editor or admin roles later.
              </p>
            </div>

            <button
              phx-click="join_clan"
              class="w-full bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 transition font-medium"
            >
              Join {@clan.name}
            </button>

            <.link
              href={~p"/"}
              class="w-full bg-gray-100 text-gray-700 px-4 py-2 rounded-md hover:bg-gray-200 transition text-center block"
            >
              Maybe Later
            </.link>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("join_clan", _params, socket) do
    user = socket.assigns.current_scope.user
    clan = socket.assigns.clan

    case ClanMemberships.create_clan_membership(user, clan, :member) do
      {:ok, _membership} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           "Welcome to #{clan.name}! You can now view events and coordinate with your clan."
         )
         |> redirect(to: ~p"/clans/#{clan.id}/")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Unable to join clan. Please try again.")
         |> redirect(to: ~p"/")}
    end
  end
end
