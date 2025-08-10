defmodule TbTips.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @event_types ["Tin Man", "CP Run", "Clan War", "Dragon Raid", "Guild Expedition", "Custom"]

  schema "events" do
    field :title, :string
    field :description, :string
    field :start_time, :utc_datetime
    field :event_type, :string
    field :created_by_name, :string

    belongs_to :clan, TbTips.Clans.Clan

    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :title,
      :description,
      :start_time,
      :event_type,
      :created_by_name,
      :clan_id
    ])
    |> validate_required([:title, :start_time, :event_type, :clan_id])
    |> validate_inclusion(:event_type, @event_types)
  end

  def event_types, do: @event_types
end
