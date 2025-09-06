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

  # add near bottom of the schema module (public fns)
  def r_offset_minutes(%__MODULE__{start_time: start}) do
    TbTips.Time.ResetClock.offset_from_start_utc(start)
  end

  def r_label(%__MODULE__{} = ev) do
    ev |> r_offset_minutes() |> TbTips.Time.ResetClock.format_r_label()
  end
end
