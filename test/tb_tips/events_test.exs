defmodule TbTips.EventsTest do
  use TbTips.DataCase

  alias TbTips.Events

  describe "events" do
    alias TbTips.Events.Event

    import TbTips.EventsFixtures

    @invalid_attrs %{description: nil, start_time: nil, event_type: nil, created_by_name: nil}

    test "list_events/0 returns all events" do
      event = event_fixture()
      assert Events.list_events() == [event]
    end

    test "get_event!/1 returns the event with given id" do
      event = event_fixture()
      assert Events.get_event!(event.id) == event
    end

    test "create_event/1 with valid data creates a event" do
      valid_attrs = %{
        description: "some description",
        start_time: ~U[2025-09-04 23:51:00Z],
        event_type: "some event_type",
        created_by_name: "some created_by_name"
      }

      assert {:ok, %Event{} = event} = Events.create_event(valid_attrs)
      assert event.description == "some description"
      assert event.start_time == ~U[2025-09-04 23:51:00Z]
      assert event.event_type == "some event_type"
      assert event.created_by_name == "some created_by_name"
    end

    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_event(@invalid_attrs)
    end

    test "update_event/2 with valid data updates the event" do
      event = event_fixture()

      update_attrs = %{
        description: "some updated description",
        start_time: ~U[2025-09-05 23:51:00Z],
        event_type: "some updated event_type",
        created_by_name: "some updated created_by_name"
      }

      assert {:ok, %Event{} = event} = Events.update_event(event, update_attrs)
      assert event.description == "some updated description"
      assert event.start_time == ~U[2025-09-05 23:51:00Z]
      assert event.event_type == "some updated event_type"
      assert event.created_by_name == "some updated created_by_name"
    end

    test "update_event/2 with invalid data returns error changeset" do
      event = event_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_event(event, @invalid_attrs)
      assert event == Events.get_event!(event.id)
    end

    test "delete_event/1 deletes the event" do
      event = event_fixture()
      assert {:ok, %Event{}} = Events.delete_event(event)
      assert_raise Ecto.NoResultsError, fn -> Events.get_event!(event.id) end
    end

    test "change_event/1 returns a event changeset" do
      event = event_fixture()
      assert %Ecto.Changeset{} = Events.change_event(event)
    end
  end
end
