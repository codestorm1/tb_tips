defmodule TbTips.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :description, :string
    field :start_time, :utc_datetime
    field :event_type, :string
    field :created_by_name, :string
    field :clan_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:description, :start_time, :event_type, :created_by_name, :clan_id])
    |> validate_required([:description, :start_time, :event_type, :created_by_name])
  end
end
