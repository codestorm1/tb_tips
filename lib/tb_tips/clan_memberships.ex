defmodule TbTips.ClanMemberships do
  @moduledoc """
  The ClanMemberships context.

  Handles all clan membership operations including role management,
  permissions, and invite-based joining.
  """

  import Ecto.Query, warn: false
  alias TbTips.Repo

  ## Membership CRUD

  @doc """
  Create a clan membership
  """
  def create_clan_membership(user, clan, role \\ :member) do
    %TbTips.Accounts.ClanMembership{}
    |> TbTips.Accounts.ClanMembership.changeset(%{
      user_id: user.id,
      clan_id: clan.id,
      role: role,
      joined_at: DateTime.utc_now()
    })
    |> Repo.insert()
  end

  @doc """
  Get user's membership in a specific clan
  """
  def get_clan_membership(user_id, clan_id) do
    Repo.get_by(TbTips.Accounts.ClanMembership, user_id: user_id, clan_id: clan_id)
  end

  @doc """
  Remove user from clan
  """
  def leave_clan(user_id, clan_id) do
    case get_clan_membership(user_id, clan_id) do
      nil ->
        {:error, :not_a_member}

      membership ->
        # Prevent last admin from leaving
        if membership.role == :admin and count_clan_admins(clan_id) == 1 do
          {:error, :cannot_leave_as_last_admin}
        else
          Repo.delete(membership)
        end
    end
  end

  ## Role Management

  @doc """
  Check if user has a specific role in clan
  """
  def has_clan_role?(user_id, clan_id, required_role) do
    case get_clan_membership(user_id, clan_id) do
      nil -> false
      membership -> role_sufficient?(membership.role, required_role)
    end
  end

  @doc """
  Check if a role meets the minimum requirement
  admin > editor > member
  """
  def role_sufficient?(user_role, required_role) do
    role_hierarchy = %{member: 1, editor: 2, admin: 3}
    role_hierarchy[user_role] >= role_hierarchy[required_role]
  end

  @doc """
  Update user's role in clan (only admins can do this)
  """
  def update_clan_role(admin_user_id, target_user_id, clan_id, new_role) do
    with true <- has_clan_role?(admin_user_id, clan_id, :admin),
         %TbTips.Accounts.ClanMembership{} = membership <-
           get_clan_membership(target_user_id, clan_id) do
      # Prevent demoting the last admin
      if membership.role == :admin and new_role != :admin do
        case count_clan_admins(clan_id) do
          1 -> {:error, :cannot_demote_last_admin}
          _ -> update_membership_role(membership, new_role)
        end
      else
        update_membership_role(membership, new_role)
      end
    else
      false -> {:error, :unauthorized}
      nil -> {:error, :membership_not_found}
    end
  end

  ## Invite System

  @doc """
  Join a clan using an invite key
  """
  def join_clan_with_invite_key(user, invite_key) do
    alias TbTips.Clans

    with %TbTips.Clans.Clan{} = clan <- Clans.get_clan_by_invite_key(invite_key),
         {:ok, membership} <- create_clan_membership(user, clan, :member) do
      {:ok, membership}
    else
      nil -> {:error, :invalid_invite_key}
      {:error, changeset} -> {:error, changeset}
    end
  end

  ## Listing Functions

  @doc """
  List all members of a clan with their roles
  """
  def list_clan_members(clan_id) do
    from(cm in TbTips.Accounts.ClanMembership,
      join: u in assoc(cm, :user),
      where: cm.clan_id == ^clan_id,
      select: %{
        display_name: u.display_name,
        user_id: u.id,
        role: cm.role,
        joined_at: cm.joined_at
      },
      order_by: [desc: cm.role, asc: cm.joined_at]
    )
    |> Repo.all()
  end

  @doc """
  Get user's clans with their roles
  """
  def list_user_clans(user_id) do
    from(cm in TbTips.Accounts.ClanMembership,
      join: c in assoc(cm, :clan),
      where: cm.user_id == ^user_id,
      select: %{
        clan: c,
        role: cm.role,
        joined_at: cm.joined_at
      },
      order_by: [desc: cm.role, asc: c.name]
    )
    |> Repo.all()
  end

  ## Private Helpers

  defp update_membership_role(membership, new_role) do
    membership
    |> TbTips.Accounts.ClanMembership.changeset(%{role: new_role})
    |> Repo.update()
  end

  defp count_clan_admins(clan_id) do
    from(cm in TbTips.Accounts.ClanMembership,
      where: cm.clan_id == ^clan_id and cm.role == :admin,
      select: count(cm.id)
    )
    |> Repo.one()
  end
end
