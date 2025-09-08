defmodule TbTips.Clans.Clan do
  use Ecto.Schema
  import Ecto.Changeset

  schema "clans" do
    field :name, :string
    field :slug, :string
    field :kingdom, :string
    field :invite_key, :string

    many_to_many :users, TbTips.Accounts.User, join_through: "clan_memberships"
    has_many :clan_memberships, TbTips.Accounts.ClanMembership
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(clan, attrs) do
    clan
    |> cast(attrs, [:name, :slug, :kingdom, :invite_key])
    |> validate_required([:name, :slug, :kingdom, :invite_key])
  end
end
