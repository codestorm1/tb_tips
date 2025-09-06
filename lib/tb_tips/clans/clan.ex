defmodule TbTips.Clans.Clan do
  use Ecto.Schema
  import Ecto.Changeset

  schema "clans" do
    field :name, :string
    field :slug, :string
    field :kingdom, :string
    field :admin_key, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(clan, attrs) do
    clan
    |> cast(attrs, [:name, :slug, :kingdom, :admin_key])
    |> validate_required([:name, :slug, :kingdom, :admin_key])
  end
end
