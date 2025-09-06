defmodule TbTipsWeb.EventComponents do
  use TbTipsWeb, :html

  # expects your Event schema to have:
  #   :description, :start_time (UTC), :event_type, :created_by_name, :clan_id
  # and you’ve added the helpers:
  #   TbTips.Events.Event.r_label/1

  attr :event, :map, required: true
  attr :user_tz, :string, default: nil
  attr :show_countdown, :boolean, default: true

  def event_card(assigns) do
    ~H"""
    <div class="rounded-2xl border border-gray-200 bg-white p-4 shadow-sm">
      <div class="flex items-start justify-between gap-3">
        <div class="flex items-center gap-2">
          <span class="inline-flex items-center rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-700">
            {@event.event_type}
          </span>
          <span class="inline-flex items-center rounded-full bg-blue-100 px-2 py-0.5 text-xs font-semibold text-blue-800">
            {TbTips.Events.Event.r_label(@event)}
          </span>
        </div>
        <div class="text-xs text-gray-400">
          by {@event.created_by_name}
        </div>
      </div>

      <div class="mt-3 text-gray-900">
        <h3 class="text-lg font-semibold leading-snug">
          {@event.description || "Event"}
        </h3>
      </div>

      <div class="mt-3 grid grid-cols-1 gap-2 sm:grid-cols-2">
        <div class="rounded-lg bg-blue-50 border border-blue-200 p-3">
          <div class="text-xs uppercase tracking-wide text-blue-800/80">
            Your Local Time — {tz_city(@user_tz)}
          </div>
          <div class="mt-1 font-mono text-sm text-blue-900">
            <%= if @user_tz do %>
              {Calendar.strftime(
                DateTime.shift_zone!(@event.start_time, @user_tz),
                "%a %Y-%m-%d %H:%M"
              )}
            <% else %>
              <span
                id={"event-#{@event.id}-local"}
                phx-hook="LocalTime"
                data-utc={DateTime.to_iso8601(@event.start_time)}
              >
              </span>
            <% end %>
          </div>
        </div>

        <div class="rounded-lg bg-gray-50 border border-gray-200 p-3">
          <div class="text-xs uppercase tracking-wide text-gray-700/80">UTC</div>
          <div class="mt-1 font-mono text-sm text-gray-900">
            {Calendar.strftime(@event.start_time, "%a %Y-%m-%d %H:%M")} UTC
          </div>
        </div>
      </div>

      <div class="mt-3 flex items-center justify-between text-sm">
        <div class="text-gray-500">
          <%= if Map.has_key?(@event, :clan) and @event.clan do %>
            Clan • {@event.clan.name}
          <% else %>
            Clan • {@event.clan_id}
          <% end %>
        </div>

        <%= if @show_countdown do %>
          <div class="font-mono text-gray-800">
            <span class="text-gray-500">Starts in</span>
            <span
              id={"event-#{@event.id}-countdown"}
              phx-hook="EventCountdown"
              data-utc={DateTime.to_iso8601(@event.start_time)}
            >
            </span>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # Helpers

  defp tz_city(nil), do: "Local"
  defp tz_city(""), do: "Local"

  defp tz_city(tz),
    do: tz |> String.split("/") |> List.last() |> String.replace("_", " ")
end
