defmodule TbTips.ClanFixtures do
  @moduledoc """
  This module defines test helpers for creating entities via the `TbTips.Clans` context.
  """

  def unique_clan_slug, do: "k#{System.unique_integer([:positive])}-test"

  def clan_fixture(attrs \\ %{}) do
    {:ok, clan} =
      attrs
      |> Enum.into(%{
        description: "Test clan description",
        kingdom: "168",
        name: "TEST",
        slug: unique_clan_slug()
      })
      |> TbTips.Clans.create_clan()

    clan
  end
end
