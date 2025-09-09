defmodule TbTips.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :name, :string
    field :start_time, :utc_datetime_usec
    field :description, :string
    field :event_type, :string
    # Keep this field if you have it
    field :created_by_name, :string

    belongs_to :clan, TbTips.Clans.Clan
    belongs_to :created_by_user, TbTips.Accounts.User

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :name,
      :start_time,
      :description,
      :event_type,
      :clan_id,
      :created_by_user_id,
      :created_by_name
    ])
    # name not required based on your existing code
    |> validate_required([:start_time, :clan_id])
    |> validate_length(:description, max: 500)
    |> foreign_key_constraint(:clan_id)
    |> foreign_key_constraint(:created_by_user_id)
  end

  # add near bottom of the schema module (public fns)
  def r_offset_minutes(%__MODULE__{start_time: start}) do
    TbTips.Time.ResetClock.offset_from_start_utc(start)
  end

  def r_label(%__MODULE__{} = ev) do
    ev |> r_offset_minutes() |> TbTips.Time.ResetClock.format_r_label()
  end
end
