defmodule TbTips.ClansTest do
  use TbTips.DataCase

  alias TbTips.Clans

  describe "clans" do
    alias TbTips.Clans.Clan

    import TbTips.ClansFixtures

    @invalid_attrs %{name: nil, slug: nil, kingdom: nil, invite_key: nil}

    test "list_clans/0 returns all clans" do
      clan = clan_fixture()
      assert Clans.list_clans() == [clan]
    end

    test "get_clan!/1 returns the clan with given id" do
      clan = clan_fixture()
      assert Clans.get_clan!(clan.id) == clan
    end

    test "create_clan/1 with valid data creates a clan" do
      valid_attrs = %{
        name: "some name",
        slug: "some slug",
        kingdom: "some kingdom",
        invite_key: "some invite_key"
      }

      assert {:ok, %Clan{} = clan} = Clans.create_clan(valid_attrs)
      assert clan.name == "some name"
      assert clan.slug == "some slug"
      assert clan.kingdom == "some kingdom"
      assert clan.invite_key == "some invite_key"
    end

    test "create_clan/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Clans.create_clan(@invalid_attrs)
    end

    test "update_clan/2 with valid data updates the clan" do
      clan = clan_fixture()

      update_attrs = %{
        name: "some updated name",
        slug: "some updated slug",
        kingdom: "some updated kingdom",
        invite_key: "some updated invite_key"
      }

      assert {:ok, %Clan{} = clan} = Clans.update_clan(clan, update_attrs)
      assert clan.name == "some updated name"
      assert clan.slug == "some updated slug"
      assert clan.kingdom == "some updated kingdom"
      assert clan.invite_key == "some updated invite_key"
    end

    test "update_clan/2 with invalid data returns error changeset" do
      clan = clan_fixture()
      assert {:error, %Ecto.Changeset{}} = Clans.update_clan(clan, @invalid_attrs)
      assert clan == Clans.get_clan!(clan.id)
    end

    test "delete_clan/1 deletes the clan" do
      clan = clan_fixture()
      assert {:ok, %Clan{}} = Clans.delete_clan(clan)
      assert_raise Ecto.NoResultsError, fn -> Clans.get_clan!(clan.id) end
    end

    test "change_clan/1 returns a clan changeset" do
      clan = clan_fixture()
      assert %Ecto.Changeset{} = Clans.change_clan(clan)
    end
  end
end
