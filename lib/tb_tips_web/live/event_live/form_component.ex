defmodule TbTipsWeb.EventLive.FormComponent do
  use TbTipsWeb, :live_component
  alias TbTips.Events

  ## RENDER

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Schedule a new event for {@clan.name}</:subtitle>
      </.header>

      <.form
        for={@form}
        id="event-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        
    <!-- Event Type -->
        <.input
          field={@form[:event_type]}
          type="select"
          label="Event Type *"
          prompt="Choose an event type"
          options={Events.Event.event_types() |> Enum.map(&{&1, &1})}
          required
        />
        
    <!-- Day Selection -->
        <.input
          field={@form[:event_day]}
          type="select"
          label="Day *"
          prompt="Choose day"
          options={day_options()}
          required
        />
        
    <!-- Hour Selection -->
        <.input
          field={@form[:event_hour]}
          type="select"
          label="Your Local Time *"
          prompt="Choose time"
          options={hour_options()}
          required
        />
        
    <!-- Show preview if both day and hour are selected -->
        <%= if @form[:event_day].value && @form[:event_hour].value do %>
          <div class="mt-4 bg-blue-50 border border-blue-200 rounded-lg p-3">
            <div class="text-sm font-medium text-blue-700">
              This will be: Reset {preview_reset_time(
                @form[:event_day].value,
                @form[:event_hour].value
              )}
            </div>
          </div>
        <% end %>
        
    <!-- Description -->
        <.input field={@form[:description]} type="textarea" label="Description (optional)" />
        
    <!-- Name -->
        <.input field={@form[:created_by_name]} type="text" label="Your Name *" required />

        <div class="mt-6">
          <.button type="submit" phx-disable-with="Saving...">Save Event</.button>
        </div>
      </.form>
    </div>
    """
  end

  ## LIFECYCLE

  def update(%{event: event} = assigns, socket) do
    changeset = Events.change_event(event)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))}
  end

  ## EVENTS

  def handle_event("validate", %{"event" => event_params}, socket) do
    changeset =
      socket.assigns.event
      |> Events.change_event(event_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"event" => event_params}, socket) do
    event_params = Map.put(event_params, "clan_id", socket.assigns.clan.id)
    save_event(socket, socket.assigns.action, event_params)
  end

  ## HELPERS

  defp day_options do
    today = Date.utc_today()

    for i <- 0..13 do
      date = Date.add(today, i)

      label =
        case i do
          0 -> "Today (#{Calendar.strftime(date, "%a %b %d")})"
          1 -> "Tomorrow (#{Calendar.strftime(date, "%a %b %d")})"
          _ -> Calendar.strftime(date, "%a %b %d")
        end

      {label, Date.to_iso8601(date)}
    end
  end

  defp hour_options do
    for hour <- 0..23 do
      label =
        case hour do
          0 -> "12:00 AM (Midnight)"
          h when h < 12 -> "#{h}:00 AM"
          12 -> "12:00 PM (Noon)"
          h -> "#{h - 12}:00 PM"
        end

      {label, hour}
    end
  end

  defp preview_reset_time(day, hour) when is_binary(day) and is_integer(hour) do
    with {:ok, date} <- Date.from_iso8601(day),
         {:ok, local_time} <- Time.new(hour, 0, 0),
         {:ok, local_dt} <- DateTime.new(date, local_time, "America/Los_Angeles"),
         {:ok, utc_dt} <- DateTime.shift_zone(local_dt, "Etc/UTC") do
      calculate_reset_offset(utc_dt)
    else
      _ -> "?"
    end
  end

  defp preview_reset_time(_, _), do: "?"

  defp calculate_reset_offset(%DateTime{} = datetime) do
    date = DateTime.to_date(datetime)

    case DateTime.new(date, ~T[18:00:00], "Etc/UTC") do
      {:ok, today_reset} ->
        diff_seconds = DateTime.diff(datetime, today_reset, :second)
        hours_diff = div(diff_seconds, 3600)

        cond do
          hours_diff > 12 ->
            {:ok, tomorrow_reset} = DateTime.new(Date.add(date, 1), ~T[18:00:00], "Etc/UTC")
            new_diff = div(DateTime.diff(datetime, tomorrow_reset, :second), 3600)
            "#{new_diff}"

          hours_diff < -12 ->
            {:ok, yesterday_reset} = DateTime.new(Date.add(date, -1), ~T[18:00:00], "Etc/UTC")
            new_diff = div(DateTime.diff(datetime, yesterday_reset, :second), 3600)
            "+#{new_diff}"

          hours_diff >= 0 ->
            "+#{hours_diff}"

          true ->
            "#{hours_diff}"
        end

      _ ->
        "?"
    end
  end

  ## SAVE

  defp save_event(socket, action, event_params) do
    save_function = apply(Events, save_action(action), [socket.assigns.event, event_params])

    case save_function do
      {:ok, event} ->
        notify_parent({:saved, event})

        {:noreply,
         socket
         |> put_flash(:info, event_action_msg(action))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_action(:edit), do: :update_event
  defp save_action(:new), do: :create_event

  defp event_action_msg(:edit), do: "Event updated successfully"
  defp event_action_msg(:new), do: "Event created successfully"

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
