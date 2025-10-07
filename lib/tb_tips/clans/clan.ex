defmodule TbTips.Clans.Clan do
  use Ecto.Schema
  import Ecto.Changeset

  schema "clans" do
    field :name, :string
    field :abbr, :string
    field :kingdom, :string
    field :invite_key, :string

    many_to_many :users, TbTips.Accounts.User, join_through: "clan_memberships"
    has_many :clan_memberships, TbTips.Accounts.ClanMembership
    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(clan, attrs) do
    clan
    |> cast(attrs, [:name, :abbr, :kingdom, :invite_key])
    |> validate_required([:name, :abbr, :kingdom, :invite_key])
    |> validate_format(:abbr, ~r/^[A-Z0-9]{3}$/i, message: "must be 3 letters/numbers")
    |> validate_format(:kingdom, ~r/^[1-9]\d{0,3}$/,
      message: "must be a number between 1 and 9999"
    )
    |> update_change(:abbr, &String.upcase/1)
  end
end
