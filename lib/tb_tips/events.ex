defmodule TbTips.Events do
  @moduledoc """
  The Events context.
  """

  import Ecto.Query, warn: false
  alias TbTips.Repo
  alias TbTips.Events.Event

  # --- Default ordering for Event everywhere: earliest first, NILs last
  defp ordered(query \\ Event) do
    from e in query,
      order_by: [asc: is_nil(e.start_time), asc: e.start_time, asc: e.id]

    # If you're on Ecto >= 3.9 with Postgres, you can use:
    # from e in query, order_by: [asc_nulls_last: e.start_time, asc: e.id]
  end

  # Use the default order in all list functions:

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

  @doc """
  Gets a single event.

  Raises `Ecto.NoResultsError` if the Event does not exist.
  """
  def get_event!(id), do: Repo.get!(Event, id)

  @doc """
  Creates a event.
  """
  def create_event(attrs \\ %{}) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a event.
  """
  def update_event(%Event{} = event, attrs) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a event.
  """
  def delete_event(%Event{} = event) do
    Repo.delete(event)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event changes.
  """
  def change_event(%Event{} = event, attrs \\ %{}) do
    Event.changeset(event, attrs)
  end
end
