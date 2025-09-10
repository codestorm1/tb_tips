defmodule TbTipsWeb.EventLiveTest do
  use TbTipsWeb.ConnCase

  import Phoenix.LiveViewTest
  import TbTips.EventsFixtures

  @create_attrs %{
    description: "some description",
    start_time: "2025-09-04T23:51:00Z",
    event_type: "some event_type",
    created_by_name: "some created_by_name"
  }
  @update_attrs %{
    description: "some updated description",
    start_time: "2025-09-05T23:51:00Z",
    event_type: "some updated event_type",
    created_by_name: "some updated created_by_name"
  }
  @invalid_attrs %{description: nil, start_time: nil, event_type: nil, created_by_name: nil}
  defp create_event(_) do
    event = event_fixture()

    %{event: event}
  end

  describe "Index" do
    setup [:create_event]

    test "lists all events", %{conn: conn, event: event} do
      {:ok, _index_live, html} = live(conn, ~p"/events")

      assert html =~ "Listing Events"
      assert html =~ event.description
    end

    test "saves new event", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/events")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Event")
               |> render_click()
               |> follow_redirect(conn, ~p"/events/new")

      assert render(form_live) =~ "New Event"

      assert form_live
             |> form("#event-form", event: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#event-form", event: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/events")

      html = render(index_live)
      assert html =~ "Event created successfully"
      assert html =~ "some description"
    end

    test "updates event in listing", %{conn: conn, event: event} do
      {:ok, index_live, _html} = live(conn, ~p"/events")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#events-#{event.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/events/#{event}/edit")

      assert render(form_live) =~ "Edit Event"

      assert form_live
             |> form("#event-form", event: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#event-form", event: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/events")

      html = render(index_live)
      assert html =~ "Event updated successfully"
      assert html =~ "some updated description"
    end

    test "deletes event in listing", %{conn: conn, event: event} do
      {:ok, index_live, _html} = live(conn, ~p"/events")

      assert index_live |> element("#events-#{event.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#events-#{event.id}")
    end
  end

  describe "Show" do
    setup [:create_event]

    test "displays event", %{conn: conn, event: event} do
      {:ok, _show_live, html} = live(conn, ~p"/events/#{event}")

      assert html =~ "Show Event"
      assert html =~ event.description
    end

    test "updates event and returns to show", %{conn: conn, event: event} do
      {:ok, show_live, _html} = live(conn, ~p"/events/#{event}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/events/#{event}/edit?return_to=show")

      assert render(form_live) =~ "Edit Event"

      assert form_live
             |> form("#event-form", event: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#event-form", event: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/events/#{event}")

      html = render(show_live)
      assert html =~ "Event updated successfully"
      assert html =~ "some updated description"
    end
  end
end
