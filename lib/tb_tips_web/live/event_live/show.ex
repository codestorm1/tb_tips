defmodule TbTipsWeb.EventLive.Show do
  use TbTipsWeb, :live_view

  alias TbTips.Events
  alias TbTips.Clans

  @impl true
  def mount(%{"clan_slug" => slug, "id" => id}, _session, socket) do
    case Clans.get_clan_by_slug(slug) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Clan not found")
         |> redirect(to: ~p"/clans")}

      clan ->
        event = Events.get_event!(id)

        # Verify event belongs to this clan
        if event.clan_id != clan.id do
          {:ok,
           socket
           |> put_flash(:error, "Event not found")
           |> redirect(to: ~p"/clans/#{clan.slug}/events")}
        else
          {:ok,
           socket
           |> assign(:page_title, "#{event.event_type} - #{clan.name}")
           |> assign_new(:user_tz, fn -> nil end)
           |> assign(:clan, clan)
           |> assign(:event, event)}
        end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="page" phx-hook="TzSender">
        <.header>
          Event {@event.id}
          <:subtitle>{@event.event_type} — {@clan.name}</:subtitle>
          <:actions>
            <.button navigate={~p"/clans/#{@clan.slug}/events"}>
              <.icon name="hero-arrow-left" />
            </.button>
            <.button
              variant="primary"
              navigate={~p"/clans/#{@clan.slug}/events/#{@event}/edit?return_to=show"}
            >
              <.icon name="hero-pencil-square" /> Edit event
            </.button>
          </:actions>
        </.header>

        <div class="rounded-2xl border border-gray-200 bg-white p-4 shadow-sm">
          <div class="flex items-center gap-2">
            <span class="inline-flex items-center rounded-full bg-blue-100 px-2 py-0.5 text-xs font-semibold text-blue-800">
              {TbTips.Time.ResetClock.offset_from_start_utc(@event.start_time)
              |> TbTips.Time.ResetClock.format_r_label()}
            </span>
            <span class="inline-flex items-center rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-700">
              {@event.event_type}
            </span>
          </div>

          <h3 class="mt-2 text-lg font-semibold">{@event.description || "Event"}</h3>

          <div class="mt-3">
            <div class="rounded-lg bg-blue-50 border border-blue-200 p-3">
              <div class="flex items-start justify-between gap-3">
                <div>
                  <div class="text-xs uppercase tracking-wide text-blue-800/80">
                    Your Local Time{if city = tz_city(@user_tz), do: " — #{city}"}
                  </div>
                  <div class="mt-1 font-mono text-lg sm:text-xl text-blue-900">
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

                <span class="inline-flex items-center rounded-xl bg-blue-600 text-white px-3 py-1 text-base sm:text-lg font-semibold tracking-tight">
                  {TbTips.Time.ResetClock.offset_from_start_utc(@event.start_time)
                  |> TbTips.Time.ResetClock.format_r_label()}
                </span>
              </div>
            </div>
          </div>

          <dl class="mt-4 grid grid-cols-1 sm:grid-cols-2 gap-3 text-sm">
            <div>
              <dt class="text-gray-500">Created by</dt>
              <dd class="text-gray-900">{@event.created_by_name}</dd>
            </div>
            <div>
              <dt class="text-gray-500">Clan</dt>
              <dd class="text-gray-900">{@clan.name}</dd>
            </div>
          </dl>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("tz", %{"tz" => tz}, socket) do
    {:noreply, assign(socket, :user_tz, tz)}
  end

  # Return nil when unknown so we don't show " — Local"
  defp tz_city(nil), do: nil
  defp tz_city(""), do: nil
  defp tz_city(tz), do: tz |> String.split("/") |> List.last() |> String.replace("_", " ")

  # turns "America/Los_Angeles" into "Los Angeles"
  defp tz_city(nil), do: "Unknown timezone"
  defp tz_city(""), do: "Unknown timezone"

  defp tz_city(tz),
    do: tz |> String.split("/") |> List.last() |> String.replace("_", " ")
end
