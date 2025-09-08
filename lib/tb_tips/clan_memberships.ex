defmodule TbTips.ClanMemberships do
  @moduledoc """
  The ClanMemberships context.
  """

  import Ecto.Query, warn: false
  alias TbTips.Repo
  alias TbTips.Accounts.{User, ClanMembership}

  @doc """
  Create a clan membership
  """
  def create_clan_membership(user, clan, role \\ :member) do
    %ClanMembership{}
    |> ClanMembership.changeset(%{
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
    Repo.get_by(ClanMembership, user_id: user_id, clan_id: clan_id)
  end

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
end
