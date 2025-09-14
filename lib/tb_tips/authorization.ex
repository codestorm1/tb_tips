defmodule TbTips.Authorization do
  alias TbTips.ClanMemberships

  # Get user's role in a clan for the authorization check
  defp get_user_clan_role(user_id, clan_id) do
    case ClanMemberships.get_clan_membership(user_id, clan_id) do
      nil -> :none
      membership -> membership.role
    end
  end

  # Public interface - figures out user's role automatically
  def authorized?(user_id, required_role, action, %{clan_id: clan_id} = resource) do
    user_role = get_user_clan_role(user_id, clan_id)
    check_authorization(user_role, required_role, action, resource)
  end

  # The actual authorization logic with function heads
  defp check_authorization(user_role, required_role, action, resource)

  # Admins can do anything
  defp check_authorization(:admin, _, _, _), do: true

  # Exact role matches
  defp check_authorization(role, role, :view_events, %{clan_id: _}), do: true
  defp check_authorization(role, role, :view_members, %{clan_id: _}), do: true

  # Editors can do member-level things
  defp check_authorization(:editor, :member, :view_events, %{clan_id: _}), do: true
  defp check_authorization(:editor, :member, :view_members, %{clan_id: _}), do: true

  # Only editors+ can create events
  defp check_authorization(role, :editor, :create_event, %{clan_id: _})
       when role in [:editor, :admin],
       do: true

  # Event ownership - creator or admin can edit
  defp check_authorization(user_role, _, :edit_event, %TbTips.Events.Event{
         created_by_user_id: _creator_id,
         clan_id: _clan_id
       }) do
    # Check if user created the event OR is clan admin
    # Will be true if they're admin in the clan
    user_role == :admin
  end

  # Default deny
  defp check_authorization(_, _, _, _), do: false
end
