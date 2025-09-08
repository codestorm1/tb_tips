defmodule TbTipsWeb.ClanLiveTest do
  use TbTipsWeb.ConnCase

  import Phoenix.LiveViewTest
  import TbTips.ClansFixtures

  @create_attrs %{
    name: "some name",
    slug: "some slug",
    kingdom: "some kingdom",
    invite_key: "some invite_key"
  }
  @update_attrs %{
    name: "some updated name",
    slug: "some updated slug",
    kingdom: "some updated kingdom",
    invite_key: "some updated invite_key"
  }
  @invalid_attrs %{name: nil, slug: nil, kingdom: nil, invite_key: nil}
  defp create_clan(_) do
    clan = clan_fixture()

    %{clan: clan}
  end

  describe "Index" do
    setup [:create_clan]

    test "lists all clans", %{conn: conn, clan: clan} do
      {:ok, _index_live, html} = live(conn, ~p"/clans")

      assert html =~ "Listing Clans"
      assert html =~ clan.name
    end

    test "saves new clan", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/clans")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Clan")
               |> render_click()
               |> follow_redirect(conn, ~p"/clans/new")

      assert render(form_live) =~ "New Clan"

      assert form_live
             |> form("#clan-form", clan: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#clan-form", clan: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/clans")

      html = render(index_live)
      assert html =~ "Clan created successfully"
      assert html =~ "some name"
    end

    test "updates clan in listing", %{conn: conn, clan: clan} do
      {:ok, index_live, _html} = live(conn, ~p"/clans")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#clans-#{clan.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/clans/#{clan}/edit")

      assert render(form_live) =~ "Edit Clan"

      assert form_live
             |> form("#clan-form", clan: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#clan-form", clan: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/clans")

      html = render(index_live)
      assert html =~ "Clan updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes clan in listing", %{conn: conn, clan: clan} do
      {:ok, index_live, _html} = live(conn, ~p"/clans")

      assert index_live |> element("#clans-#{clan.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#clans-#{clan.id}")
    end
  end

  describe "Show" do
    setup [:create_clan]

    test "displays clan", %{conn: conn, clan: clan} do
      {:ok, _show_live, html} = live(conn, ~p"/clans/#{clan}")

      assert html =~ "Show Clan"
      assert html =~ clan.name
    end

    test "updates clan and returns to show", %{conn: conn, clan: clan} do
      {:ok, show_live, _html} = live(conn, ~p"/clans/#{clan}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/clans/#{clan}/edit?return_to=show")

      assert render(form_live) =~ "Edit Clan"

      assert form_live
             |> form("#clan-form", clan: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#clan-form", clan: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/clans/#{clan}")

      html = render(show_live)
      assert html =~ "Clan updated successfully"
      assert html =~ "some updated name"
    end
  end
end
