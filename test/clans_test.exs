defmodule TbTips.ClansTest do
  use TbTips.DataCase

  alias TbTips.Clans

  describe "clans" do
    alias TbTips.Clans.Clan

    import TbTips.ClanFixtures

    @invalid_attrs %{description: nil, kingdom: nil, name: nil, slug: nil}

    test "list_clans/0 returns all clans" do
      clan = clan_fixture()
      assert Clans.list_clans() == [clan]
    end

    test "get_clan!/1 returns the clan with given id" do
      clan = clan_fixture()
      assert Clans.get_clan!(clan.id) == clan
    end

    test "get_clan_by_slug!/1 returns the clan with given slug" do
      clan = clan_fixture(%{slug: "K168-COC"})
      assert Clans.get_clan_by_slug!("K168-COC") == clan
    end

    test "create_clan/1 with valid data creates a clan" do
      valid_attrs = %{
        description: "Chaos of Crazies",
        kingdom: "168",
        name: "COC",
        slug: "K168-COC"
      }

      assert {:ok, %Clan{} = clan} = Clans.create_clan(valid_attrs)
      assert clan.description == "Chaos of Crazies"
      assert clan.kingdom == "168"
      assert clan.name == "COC"
      assert clan.slug == "K168-COC"
    end

    test "create_clan/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Clans.create_clan(@invalid_attrs)
    end

    test "create_clan/1 with duplicate slug returns error" do
      clan_fixture(%{slug: "K168-COC"})

      assert {:error, %Ecto.Changeset{} = changeset} =
               Clans.create_clan(%{slug: "K168-COC", name: "COC", kingdom: "168"})

      assert "has already been taken" in errors_on(changeset).slug
    end

    test "create_clan/1 validates slug format" do
      invalid_slugs = ["K168 COC", "K168/COC", "K168@COC", "ab"]

      for slug <- invalid_slugs do
        assert {:error, %Ecto.Changeset{} = changeset} =
                 Clans.create_clan(%{slug: slug, name: "COC", kingdom: "168"})

        assert changeset.errors[:slug] != nil
      end
    end

    test "update_clan/2 with valid data updates the clan" do
      clan = clan_fixture()

      update_attrs = %{
        description: "Updated description",
        kingdom: "169",
        name: "Updated COC",
        slug: "K169-COC"
      }

      assert {:ok, %Clan{} = clan} = Clans.update_clan(clan, update_attrs)
      assert clan.description == "Updated description"
      assert clan.kingdom == "169"
      assert clan.name == "Updated COC"
      assert clan.slug == "K169-COC"
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
