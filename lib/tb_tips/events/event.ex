defmodule TbTips.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @event_types ["Tin Man", "CP Run", "KvK Hunting", "Heriocs", "Citadels", "Other"]

  schema "events" do
    field :description, :string
    field :start_time, :utc_datetime
    field :event_type, :string
    field :created_by_name, :string

    # Virtual fields for form input
    field :event_day, :string, virtual: true
    field :event_hour, :integer, virtual: true

    belongs_to :clan, TbTips.Clans.Clan

    timestamps()
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :description,
      :event_type,
      :created_by_name,
      :clan_id,
      :event_day,
      :event_hour
    ])
    |> validate_required([:event_type, :created_by_name, :clan_id, :event_day, :event_hour])
    |> validate_inclusion(:event_type, @event_types)
    |> build_start_time()
    |> validate_required([:start_time])
  end

  defp build_start_time(%Ecto.Changeset{} = changeset) do
    day = get_field(changeset, :event_day)
    hour = get_field(changeset, :event_hour)

    case build_datetime(day, hour) do
      {:ok, datetime} ->
        put_change(changeset, :start_time, datetime)

      {:error, _} ->
        add_error(changeset, :start_time, "Invalid date/time combination")
    end
  end

  defp build_datetime(day, hour) when is_binary(day) and is_integer(hour) do
    with {:ok, date} <- Date.from_iso8601(day),
         {:ok, local_time} <- Time.new(hour, 0, 0),
         {:ok, local_dt} <- DateTime.new(date, local_time, "America/Los_Angeles"),
         {:ok, utc_dt} <- DateTime.shift_zone(local_dt, "Etc/UTC") do
      {:ok, utc_dt}
    else
      _ -> {:error, :invalid_datetime}
    end
  end

  defp build_datetime(_, _), do: {:error, :missing_fields}

  def event_types, do: @event_types
end
