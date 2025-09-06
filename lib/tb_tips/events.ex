defmodule TbTips.Events do
  @moduledoc """
  The Events context.
  """

  import Ecto.Query, warn: false
  alias TbTips.Repo
  alias TbTips.Events.Event

  @doc """
  Returns the list of events.
  """
  def list_events do
    Repo.all(Event)
  end

  @doc """
  Returns events for a specific clan.
  """
  def list_events_for_clan(clan_id) do
    from(e in Event,
      where: e.clan_id == ^clan_id,
      order_by: [asc: e.start_time]
    )
    |> Repo.all()
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
