defmodule TbTips.Accounts.ClanMembership do
  use Ecto.Schema
  import Ecto.Changeset

  @roles ~w(admin editor member)a

  schema "clan_memberships" do
    belongs_to :user, TbTips.Accounts.User
    belongs_to :clan, TbTips.Clans.Clan
    field :role, Ecto.Enum, values: @roles, default: :member
    field :joined_at, :utc_datetime_usec

    timestamps()
  end

  def changeset(clan_membership, attrs) do
    clan_membership
    |> cast(attrs, [:user_id, :clan_id, :role, :joined_at])
    |> validate_required([:user_id, :clan_id, :role])
    |> validate_inclusion(:role, @roles)
    |> unique_constraint([:user_id, :clan_id])
  end

  def roles, do: @roles
end
