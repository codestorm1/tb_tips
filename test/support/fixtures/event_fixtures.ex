defmodule TbTips.EventFixtures do
  @moduledoc """
  This module defines test helpers for creating entities via the `TbTips.Events` context.
  """

  def event_fixture(attrs \\ %{}) do
    clan =
      (attrs[:clan_id] && TbTips.Clans.get_clan!(attrs[:clan_id])) ||
        TbTips.ClanFixtures.clan_fixture()

    {:ok, event} =
      attrs
      |> Enum.into(%{
        description: "Test event description",
        event_type: "Tin Man",
        start_time: DateTime.add(DateTime.utc_now(), 3600, :second),
        title: "Test Event",
        clan_id: clan.id,
        created_by_name: "TestPlayer"
      })
      |> TbTips.Events.create_event()

    event
  end
end
