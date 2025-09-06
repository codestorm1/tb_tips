defmodule TbTips.EventsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TbTips.Events` context.
  """

  @doc """
  Generate a event.
  """
  def event_fixture(attrs \\ %{}) do
    {:ok, event} =
      attrs
      |> Enum.into(%{
        created_by_name: "some created_by_name",
        description: "some description",
        event_type: "some event_type",
        start_time: ~U[2025-09-04 23:51:00Z]
      })
      |> TbTips.Events.create_event()

    event
  end
end
