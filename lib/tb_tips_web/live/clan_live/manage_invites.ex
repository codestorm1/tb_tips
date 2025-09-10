# Add this to your clan admin page or create a separate management page

defmodule TbTipsWeb.ClanLive.ManageInvites do
  use TbTipsWeb, :live_view
  alias TbTips.{Clans, ClanMemberships}

  def mount(%{"clan_slug" => slug}, _session, socket) do
    case Clans.get_clan_by_slug(slug) do
      nil ->
        {:ok, redirect(socket, to: ~p"/clans")}

      clan ->
        user = socket.assigns.current_scope.user

        if user && ClanMemberships.has_clan_role?(user.id, clan.id, :admin) do
          {:ok,
           socket
           |> assign(:clan, clan)
           |> assign(:page_title, "Manage Invites - #{clan.name}")}
        else
          {:ok,
           socket
           |> put_flash(:error, "You must be an admin to manage invites")
           |> redirect(to: ~p"/clans/#{clan.slug}")}
        end
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-4 py-8">
      <.header>
        Manage Clan Invites
        <:subtitle>{@clan.name} - Kingdom {@clan.kingdom}</:subtitle>
      </.header>

      <div class="bg-white shadow rounded-lg p-6 space-y-6">
        <!-- Current Invite Link -->
        <div>
          <h3 class="text-lg font-medium text-gray-900 mb-4">Current Invite Link</h3>

          <div class="flex items-center space-x-3">
            <input
              type="text"
              readonly
              value={invite_url(@clan)}
              id="invite-link-input"
              class="flex-1 px-3 py-2 border border-gray-300 rounded-md bg-gray-50 text-sm font-mono"
            />
            <button
              type="button"
              phx-click="copy_link"
              class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 text-sm"
            >
              Copy Link
            </button>
          </div>

          <p class="mt-2 text-sm text-gray-600">
            Share this link with players you want to invite. They'll join as members and you can promote them later.
          </p>
        </div>
        
    <!-- Actions -->
        <div class="border-t pt-6">
          <h3 class="text-lg font-medium text-gray-900 mb-4">Invite Management</h3>

          <div class="space-y-4">
            <div class="flex items-center justify-between p-4 border border-yellow-200 bg-yellow-50 rounded-lg">
              <div>
                <h4 class="font-medium text-yellow-800">Regenerate Invite Link</h4>
                <p class="text-sm text-yellow-700">
                  This will invalidate the current link and create a new one.
                </p>
              </div>
              <button
                phx-click="regenerate_key"
                phx-confirm="This will make the current invite link stop working. Anyone with the old link won't be able to join. Continue?"
                class="px-4 py-2 bg-yellow-600 text-white rounded-md hover:bg-yellow-700"
              >
                Regenerate
              </button>
            </div>
            
    <!-- Recent Members (optional) -->
            <div class="border border-gray-200 rounded-lg p-4">
              <h4 class="font-medium text-gray-900 mb-3">Recent Members</h4>
              <div class="space-y-2">
                <%= for member <- recent_members(@clan.id) do %>
                  <div class="flex items-center justify-between text-sm">
                    <span class="text-gray-900">{member.email}</span>
                    <div class="flex items-center space-x-2">
                      <span class="text-xs px-2 py-1 bg-gray-100 rounded-full">
                        {String.capitalize(to_string(member.role))}
                      </span>
                      <span class="text-gray-500">{relative_time(member.joined_at)}</span>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Usage Tips -->
        <div class="border-t pt-6">
          <h3 class="text-lg font-medium text-gray-900 mb-4">Tips</h3>
          <ul class="text-sm text-gray-600 space-y-2">
            <li>• New members join with "Member" role by default</li>
            <li>
              • You can promote members to "Editor" (can create events) or "Admin" (full access)
            </li>
            <li>• Regenerate the invite link if it gets shared publicly or compromised</li>
            <li>• The invite link works for both registration and existing users</li>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("regenerate_key", _params, socket) do
    user = socket.assigns.current_scope.user
    clan = socket.assigns.clan

    case Clans.regenerate_invite_key(clan.id, user.id) do
      {:ok, updated_clan} ->
        {:noreply,
         socket
         |> assign(:clan, updated_clan)
         |> put_flash(:info, "Invite link regenerated successfully!")}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You don't have permission to regenerate invite links")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to regenerate invite link")}
    end
  end

  def handle_event("copy_link", _params, socket) do
    # The actual copying happens in JavaScript
    {:noreply,
     socket
     |> put_flash(:info, "Invite link copied to clipboard!")}
  end

  # Helper functions
  defp invite_url(clan) do
    Clans.get_invite_url(clan, TbTipsWeb.Endpoint.url())
  end

  defp recent_members(clan_id) do
    ClanMemberships.list_clan_members(clan_id)
    |> Enum.take(5)
  end

  defp relative_time(datetime) do
    # Simple relative time - you could use a library like Timex for better formatting
    diff = DateTime.diff(DateTime.utc_now(), datetime, :hour)

    cond do
      diff < 1 -> "Just now"
      diff < 24 -> "#{diff}h ago"
      diff < 24 * 7 -> "#{div(diff, 24)}d ago"
      true -> "#{div(diff, 24 * 7)}w ago"
    end
  end
end
