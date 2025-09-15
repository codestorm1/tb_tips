defmodule TbTips.Events do
  @moduledoc """
  The Events context.
  """

  import Ecto.Query, warn: false
  alias TbTips.Repo
  alias TbTips.Events.Event

  # --- Default ordering for Event everywhere: earliest first, NILs last
  defp ordered(query) do
    from e in query, order_by: [asc_nulls_last: e.start_time, asc: e.id]
  end

  def list_events do
    Event |> ordered() |> Repo.all()
  end

  def list_events_for_clan(clan_id) do
    Event
    |> where([e], e.clan_id == ^clan_id)
    |> ordered()
    |> Repo.all()
  end

  # If you expose a base query for composition:
  def events_query_for_clan(clan_id) do
    Event
    |> where([e], e.clan_id == ^clan_id)
    |> ordered()
  end

  @doc """
  Returns upcoming events for a specific clan.
  """
  def list_upcoming_events_for_clan(clan_id) do
    now = DateTime.utc_now()

    from(e in Event,
      where: e.clan_id == ^clan_id and e.start_time >= ^now,
      order_by: [asc: e.start_time],
      limit: 10
    )
    |> Repo.all()
  end

  def list_user_events(user_id) do
    now = DateTime.utc_now()

    from(e in Event,
      join: cm in TbTips.Accounts.ClanMembership,
      on: cm.clan_id == e.clan_id,
      join: c in TbTips.Clans.Clan,
      on: c.id == e.clan_id,
      where: cm.user_id == ^user_id and e.start_time >= ^now,
      select: %{event: e, clan: c},
      order_by: [asc_nulls_last: e.start_time],
      limit: 10
    )
    |> Repo.all()
  end

  @doc """
  Gets a single event.

  Raises `Ecto.NoResultsError` if the Event does not exist.
  """
  def get_event!(id), do: Repo.get!(Event, id)

  def create_event(attrs) do
    case %Event{} |> Event.changeset(attrs) |> Repo.insert() do
      {:ok, event} ->
        Phoenix.PubSub.broadcast(TbTips.PubSub, "clan:#{event.clan_id}", {:event_created, event})
        {:ok, event}

      error ->
        error
    end
  end

  def update_event(event, attrs) do
    case event |> Event.changeset(attrs) |> Repo.update() do
      {:ok, updated_event} ->
        Phoenix.PubSub.broadcast(
          TbTips.PubSub,
          "clan:#{updated_event.clan_id}",
          {:event_updated, updated_event}
        )

        {:ok, updated_event}

      error ->
        error
    end
  end

  def delete_event(event) do
    case Repo.delete(event) do
      {:ok, deleted_event} ->
        Phoenix.PubSub.broadcast(
          TbTips.PubSub,
          "clan:#{deleted_event.clan_id}",
          {:event_deleted, deleted_event.id}
        )

        {:ok, deleted_event}

      error ->
        error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event changes.
  """
  def change_event(%Event{} = event, attrs \\ %{}) do
    Event.changeset(event, attrs)
  end
end
