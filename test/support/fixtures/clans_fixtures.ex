defmodule TbTips.ClansFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TbTips.Clans` context.
  """

  @doc """
  Generate a clan.
  """
  def clan_fixture(attrs \\ %{}) do
    {:ok, clan} =
      attrs
      |> Enum.into(%{
        invite_key: "some invite_key",
        kingdom: "some kingdom",
        name: "some name",
        slug: "some slug"
      })
      |> TbTips.Clans.create_clan()

    clan
  end
end
