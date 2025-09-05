defmodule TbTips.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @event_types ["Tin Man", "CP Run", "KvK Hunting", "Heroics", "Citadels", "Other", "Custom"]

  schema "events" do
    field :description, :string
    field :start_time, :utc_datetime
    field :event_type, :string
    field :created_by_name, :string

    belongs_to :clan, TbTips.Clans.Clan

    timestamps()
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:description, :start_time, :event_type, :created_by_name, :clan_id])
    |> validate_required([:start_time, :event_type, :created_by_name, :clan_id])
    |> validate_inclusion(:event_type, @event_types)
  end

  def event_types, do: @event_types

  def r_offset_minutes(%__MODULE__{start_time: start}) do
    TbTips.Time.ResetClock.offset_from_start_utc(start)
  end

  def r_label(%__MODULE__{} = ev) do
    ev |> r_offset_minutes() |> TbTips.Time.ResetClock.format_r_label()
  end
end
