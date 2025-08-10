defmodule TbTips.Clans.Clan do
  use Ecto.Schema
  import Ecto.Changeset

  schema "clans" do
    field :slug, :string
    field :name, :string
    field :kingdom, :string
    field :description, :string

    has_many :events, TbTips.Events.Event, foreign_key: :clan_id

    timestamps()
  end

  @doc false
  def changeset(clan, attrs) do
    clan
    |> cast(attrs, [:slug, :name, :kingdom, :description])
    |> validate_required([:slug, :name, :kingdom])
    |> validate_format(:slug, ~r/^[a-zA-Z0-9\-]+$/,
      message: "must contain only letters, numbers, and dashes"
    )
    |> validate_length(:slug, min: 3, max: 50)
    |> unique_constraint(:slug)
  end
end
