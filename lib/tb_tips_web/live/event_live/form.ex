defmodule TbTipsWeb.EventLive.Form do
  use TbTipsWeb, :live_view

  alias TbTips.{Events, Clans}
  alias TbTips.Events.Event

  @impl true
  def mount(params, _session, socket) do
    socket = assign_new(socket, :user_tz, fn -> nil end)

    clan = Clans.get_clan_by_slug!(params["clan_slug"])

    {event, changeset, page_title, live_action} =
      case params do
        %{"id" => id} ->
          ev = Events.get_event!(id)
          {ev, Events.change_event(ev), "Edit Event", :edit}

        _ ->
          ev = %Event{clan_id: clan.id}
          {ev, Events.change_event(ev), "New Event", :new}
      end

    {:ok,
     socket
     |> assign(:clan, clan)
     |> assign(:event, event)
     |> assign(:form, to_form(changeset))
     |> assign(:page_title, page_title)
     |> assign(:live_action, live_action)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="event-form-page" phx-hook="TzSender">
        <.header>
          {@page_title}
          <:subtitle>for {@clan.name}</:subtitle>
          <:actions>
            <.button navigate={~p"/clans/#{@clan.slug}/events"}>
              <.icon name="hero-arrow-left" /> Back
            </.button>
          </:actions>
        </.header>

        <.form for={@form} id="event-form" phx-change="validate" phx-submit="save" class="space-y-4">
          <.input field={@form[:event_type]} type="text" label="Event type" />
          <.input field={@form[:description]} type="textarea" label="Description" />
          <.input field={@form[:created_by_name]} type="text" label="Your name" />

          <div class="space-y-1">
            <label for="start_time_local" class="block text-sm font-medium text-gray-700">
              Start time
            </label>

            <input
              type="datetime-local"
              id="start_time_local"
              name="event[start_time_local]"
              value={local_input_value(@event.start_time, @user_tz)}
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-orange-500 focus:ring-orange-500"
            />

            <div class="mt-1 text-xs text-gray-600">
              Time in {@user_tz || "Local"}
            </div>
          </div>

          <footer class="mt-4 flex gap-2">
            <.button variant="primary" phx-disable-with="Saving...">
              <.icon name="hero-check" /> Save Event
            </.button>
            <.button navigate={~p"/clans/#{@clan.slug}/events"} type="button">
              Cancel
            </.button>
          </footer>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  # ---- Events

  @impl true
  def handle_event("tz", %{"tz" => tz}, socket) do
    {:noreply, assign(socket, :user_tz, tz)}
  end

  @impl true
  def handle_event("validate", %{"event" => params}, socket) do
    params = put_start_time_utc(params, socket.assigns.user_tz)

    changeset =
      socket.assigns.event
      |> Events.change_event(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"event" => params}, socket) do
    params =
      params
      |> put_start_time_utc(socket.assigns.user_tz)
      |> maybe_add_user_id(socket.assigns[:current_user])

    case socket.assigns.live_action do
      :edit ->
        case Events.update_event(socket.assigns.event, params) do
          {:ok, ev} ->
            # Broadcast the update
            Phoenix.PubSub.broadcast(
              TbTips.PubSub,
              "clan:#{socket.assigns.clan.id}",
              {:event_updated, ev}
            )

            {:noreply,
             socket
             |> put_flash(:info, "Event updated successfully")
             |> push_navigate(to: ~p"/clans/#{socket.assigns.clan.slug}/events")}

          {:error, cs} ->
            {:noreply, assign(socket, :form, to_form(cs))}
        end

      :new ->
        params = Map.put(params, "clan_id", socket.assigns.clan.id)

        case Events.create_event(params) do
          {:ok, ev} ->
            # Broadcast the new event
            Phoenix.PubSub.broadcast(
              TbTips.PubSub,
              "clan:#{socket.assigns.clan.id}",
              {:event_created, ev}
            )

            {:noreply,
             socket
             |> put_flash(:info, "Event created successfully")
             |> push_navigate(to: ~p"/clans/#{socket.assigns.clan.slug}/events")}

          {:error, cs} ->
            {:noreply, assign(socket, :form, to_form(cs))}
        end
    end
  end

  # ---- Helpers

  # For the input's value attribute
  defp local_input_value(nil, _tz), do: nil

  defp local_input_value(%DateTime{} = utc, tz) do
    tz = tz || "Etc/UTC"

    utc
    |> DateTime.shift_zone!(tz)
    |> Calendar.strftime("%Y-%m-%dT%H:%M")
  end

  # Convert "YYYY-MM-DDTHH:MM" (local) -> UTC ISO8601 "YYYY-MM-DDTHH:MM:SSZ"
  defp put_start_time_utc(params, tz) do
    case Map.get(params, "start_time_local") do
      nil ->
        params

      "" ->
        Map.put(params, "start_time", nil)

      local_str ->
        with {:ok, naive} <- NaiveDateTime.from_iso8601(local_str <> ":00"),
             {:ok, localdt} <- DateTime.from_naive(naive, tz || "Etc/UTC") do
          utc = DateTime.shift_zone!(localdt, "Etc/UTC")
          Map.put(params, "start_time", DateTime.to_iso8601(utc))
        else
          _ -> params
        end
    end
  end

  # Add user_id if user is logged in
  defp maybe_add_user_id(params, user) when is_nil(user), do: params
  defp maybe_add_user_id(params, user), do: Map.put(params, "created_by_user_id", user.id)
end
