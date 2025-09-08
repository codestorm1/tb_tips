defmodule TbTipsWeb.EventLive.Index do
  alias Phoenix.LiveView
  use TbTipsWeb, :live_view

  alias TbTips.Events
  alias TbTips.Clans
  alias Phoenix.LiveView.JS

  @impl LiveView
  def mount(%{"clan_slug" => slug}, _session, socket) do
    case Clans.get_clan_by_slug(slug) do
      # existing error handling
      nil ->
        {:ok, socket}

      clan ->
        events = Events.list_events_for_clan(clan.id)

        # Subscribe to real-time updates for this clan
        if connected?(socket) do
          Phoenix.PubSub.subscribe(TbTips.PubSub, "clan:#{clan.id}")
        end

        {:ok,
         socket
         |> assign(:user_tz, nil)
         |> assign(:clan, clan)
         #  |> assign(:is_admin, is_admin)
         #  |> assign(:page_title, page_title(is_admin, clan.name))
         |> assign(:events, events)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <!-- send browser IANA TZ once -->
    <div id="tz-sender" phx-hook="TzSender"></div>

    <!-- Wider container -->
    <div class="mx-auto max-w-7xl px-6 lg:px-10">
      <div class="mt-8 flex items-center justify-between gap-3">
        <div>
          <h1 class="text-2xl font-semibold text-gray-900">
            {@clan.name} {if @is_admin, do: "Events", else: "Schedule"}
          </h1>
          <!-- Bigger kingdom line -->
          <p class="text-base text-gray-600">Kingdom {@clan.kingdom}</p>
        </div>

        <div class="flex items-center gap-2">
          <.link
            :if={@is_admin}
            navigate={~p"/clans/#{@clan.slug}/events/new"}
            class="btn btn-primary"
          >
            + New Event
          </.link>
          <%!-- <.link navigate={~p"/clans/#{@clan.slug}"} class="btn btn-ghost">← Back to Clan</.link> --%>
        </div>
      </div>

      <section class="mt-6 overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm">
        <!-- Desktop Table Header (hidden on mobile) -->
        <div class="hidden md:grid grid-cols-12 items-center gap-3 bg-gray-50 px-5 py-2.5 text-xs font-medium text-gray-600">
          <div class="col-span-2">Event</div>
          <div class="col-span-4">When</div>
          <div class="col-span-2">Countdown</div>
          <div class="col-span-3">Description</div>
          <div class="col-span-1 text-right">Actions</div>
        </div>

        <div class="divide-y divide-gray-200">
          <%= for event <- @events do %>
            <!-- Desktop Table Row (hidden on mobile) -->
            <div
              id={"event-#{event.id}-desktop"}
              class="hidden md:grid grid-cols-12 items-start gap-3 px-5 py-4 hover:bg-gray-50"
            >
              <!-- Event -->
              <div class="col-span-2 min-w-0">
                <.link
                  navigate={~p"/clans/#{@clan.slug}/events/#{event.id}"}
                  class="block hover:underline"
                >
                  <div class="inline-flex items-center rounded-full bg-gray-100 px-2.5 py-1 text-xs font-medium text-gray-800">
                    {event.event_type}
                  </div>
                  <div class="mt-1 text-xs text-gray-500">
                    by <span class="text-gray-800">{event.created_by_name}</span>
                  </div>
                </.link>
              </div>
              
    <!-- When -->
              <div class="col-span-4 min-w-0">
                <div class="flex items-start gap-3">
                  <span
                    class="inline-flex items-center rounded-xl bg-blue-600 px-3 py-1 text-sm font-semibold text-white"
                    title="Offset from RESET (8:00PM Cyprus)"
                  >
                    {TbTips.Time.ResetClock.offset_from_start_utc(event.start_time)
                    |> TbTips.Time.ResetClock.format_r_label()}
                  </span>

                  <div class="flex flex-col leading-tight">
                    <span
                      id={"t-#{event.id}"}
                      phx-hook="LocalTime"
                      data-utc={DateTime.to_iso8601(event.start_time)}
                      class="font-mono text-sm text-gray-900 whitespace-nowrap"
                    >
                    </span>
                    <span class="text-xs text-gray-500 mt-0.5">
                      {tz_city(@user_tz) || "Local"} Time
                    </span>
                  </div>
                </div>
              </div>
              
    <!-- Countdown -->
              <div class="col-span-2 min-w-0">
                <div
                  id={"countdown-#{event.id}"}
                  class={countdown_style(event.start_time)}
                  phx-hook="EventCountdown"
                  data-utc={DateTime.to_iso8601(event.start_time)}
                >
                  Calculating...
                </div>
              </div>
              
    <!-- Description -->
              <div class="col-span-3 min-w-0 text-sm text-gray-800">
                <.description_cell text={event.description} max_lines={8} />
              </div>
              
    <!-- Actions -->
              <div class="col-span-1 text-right text-sm">
                <%= if @is_admin do %>
                  <.link
                    navigate={~p"/clans/#{@clan.slug}/events/#{event.id}/edit"}
                    class="hover:underline"
                  >
                    Edit
                  </.link>
                  <span class="mx-1 text-gray-400">·</span>
                  <.link
                    phx-click={JS.push("delete", value: %{id: event.id})}
                    data-confirm="Delete this event?"
                    class="hover:underline"
                  >
                    Delete
                  </.link>
                <% else %>
                  <span class="text-gray-400">—</span>
                <% end %>
              </div>
            </div>
            
    <!-- Mobile Card Layout (hidden on desktop) -->
            <div
              id={"event-#{event.id}-mobile"}
              class="block md:hidden p-4 hover:bg-gray-50"
            >
              <.link
                navigate={~p"/clans/#{@clan.slug}/events/#{event.id}"}
                class="block"
              >
                <!-- Event Header -->
                <div class="flex items-start justify-between mb-3">
                  <div class="flex-1 min-w-0">
                    <div class="flex items-center gap-2 mb-1">
                      <span class="inline-flex items-center rounded-full bg-gray-100 px-2.5 py-1 text-xs font-medium text-gray-800">
                        {event.event_type}
                      </span>
                      <span class="inline-flex items-center rounded-xl bg-blue-600 px-2 py-1 text-xs font-semibold text-white">
                        {TbTips.Time.ResetClock.offset_from_start_utc(event.start_time)
                        |> TbTips.Time.ResetClock.format_r_label()}
                      </span>
                    </div>
                    <div class="text-xs text-gray-500">
                      by {event.created_by_name}
                    </div>
                  </div>
                  
    <!-- Countdown -->
                  <div
                    id={"countdown-mobile-#{event.id}"}
                    class={[countdown_style(event.start_time), "ml-3"]}
                    phx-hook="EventCountdown"
                    data-utc={DateTime.to_iso8601(event.start_time)}
                  >
                    Calculating...
                  </div>
                </div>
                
    <!-- Time Display -->
                <div class="mb-3">
                  <div class="flex items-center text-sm text-gray-900">
                    <span
                      id={"t-mobile-#{event.id}"}
                      phx-hook="LocalTime"
                      data-utc={DateTime.to_iso8601(event.start_time)}
                      class="font-mono"
                    >
                    </span>
                    <span class="text-xs text-gray-500 ml-2">
                      {@user_tz || "Local"} Time
                    </span>
                  </div>
                </div>
                
    <!-- Description (mobile optimized) -->
                <%= if event.description && String.trim(event.description) != "" do %>
                  <div class="text-sm text-gray-700 mb-3">
                    <.description_cell text={event.description} max_lines={2} />
                  </div>
                <% end %>
              </.link>
              
    <!-- Mobile Actions -->
              <%= if @is_admin do %>
                <div class="flex items-center gap-4 pt-3 border-t border-gray-100">
                  <.link
                    navigate={~p"/clans/#{@clan.slug}/events/#{event.id}/edit"}
                    class="text-sm text-blue-600 hover:underline"
                  >
                    Edit
                  </.link>
                  <.link
                    phx-click={JS.push("delete", value: %{id: event.id})}
                    data-confirm="Delete this event?"
                    class="text-sm text-red-600 hover:underline"
                  >
                    Delete
                  </.link>
                </div>
              <% end %>
            </div>
          <% end %>

          <%= if @events == [] do %>
            <div class="px-5 py-8 text-sm text-gray-500">No events yet.</div>
          <% end %>
        </div>
      </section>
    </div>
    """
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    is_admin = socket.assigns.live_action != :public

    {:noreply,
     socket
     |> assign(:is_admin, is_admin)
     |> assign(:page_title, page_title(is_admin, socket.assigns.clan.name))}
  end

  # Browser tz from app.js Hook
  @impl true
  def handle_event("tz", %{"tz" => tz}, socket) do
    {:noreply, assign(socket, :user_tz, tz)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    if socket.assigns.is_admin do
      event = Events.get_event!(id)

      if event.clan_id == socket.assigns.clan.id do
        {:ok, _} = Events.delete_event(event)

        {:noreply,
         assign(socket, :events, Enum.reject(socket.assigns.events, &(&1.id == event.id)))}
      else
        {:noreply, put_flash(socket, :error, "Cannot delete event from another clan")}
      end
    else
      {:noreply, put_flash(socket, :error, "Not allowed")}
    end
  end

  defp page_title(true, clan_name), do: "#{clan_name} Events"
  defp page_title(false, clan_name), do: "#{clan_name} Schedule"

  # "America/Los_Angeles" -> "Los Angeles"
  defp tz_city(nil), do: nil
  defp tz_city(""), do: nil
  defp tz_city(tz), do: tz |> String.split("/") |> List.last() |> String.replace("_", " ")

  # defp within_24_hours?(start_time) do
  #   now = DateTime.utc_now()
  #   diff_hours = DateTime.diff(start_time, now, :hour)
  #   diff_hours >= 0 and diff_hours <= 24
  # end

  # === Description cell (function component) ================================

  attr :text, :string, default: nil
  attr :max_lines, :integer, default: 8

  def description_cell(assigns) do
    lines =
      assigns.text
      |> to_string_safe()
      |> normalize_breaks()
      |> String.split(~r/\r?\n/, trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.take(assigns.max_lines)

    bullets? = bullets?(lines)

    assigns =
      assigns
      |> assign(:lines, lines)
      |> assign(:bullets?, bullets?)

    ~H"""
    <%= if @lines == [] do %>
      <div class="text-gray-400">—</div>
    <% else %>
      <%= if @bullets? do %>
        <ul class="list-disc pl-5 space-y-1 leading-snug break-words">
          <%= for l <- @lines do %>
            <li>{strip_bullet(l)}</li>
          <% end %>
        </ul>
      <% else %>
        <!-- Preserve newlines, allow multi-line preview -->
        <div class="whitespace-pre-line leading-snug break-words">
          {Enum.join(@lines, "\n")}
        </div>
      <% end %>
    <% end %>
    """
  end

  # In your LiveView
  @spec handle_info({:event_updated, any()}, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  @impl LiveView
  def handle_info({:event_updated, event}, socket) do
    {:noreply, stream_insert(socket, :events, event)}
  end

  # Helpers for description parsing
  defp to_string_safe(nil), do: ""
  defp to_string_safe(s) when is_binary(s), do: s

  defp normalize_breaks(text) do
    text
    |> String.replace(~r/<br\s*\/?>/i, "\n")
    |> String.replace(~r/\n{3,}/, "\n\n")
  end

  defp bullets?(lines) when lines == [], do: false

  defp bullets?(lines) do
    bullet_count = Enum.count(lines, &String.match?(&1, ~r/^\s*([*•-])\s+/))
    bullet_count >= max(1, div(length(lines), 2))
  end

  defp strip_bullet(line) do
    String.replace(line, ~r/^\s*([*•-])\s+/, "")
  end

  defp countdown_style(start_time) do
    now = DateTime.utc_now()
    diff_minutes = DateTime.diff(start_time, now, :minute)

    cond do
      # Event started but still ongoing (within 30 minutes)
      diff_minutes <= 0 and diff_minutes >= -30 ->
        "font-medium text-green-700 bg-green-100 px-2 py-1 rounded border-green-300 border text-sm"

      # Event ended (more than 30 minutes ago)
      diff_minutes < -30 ->
        "text-gray-400 text-sm line-through"

      # Imminent (15 minutes or less)
      diff_minutes <= 15 and diff_minutes > 0 ->
        "font-bold text-white bg-red-600 px-3 py-1 rounded-full text-sm animate-pulse"

      # Urgent (30 minutes or less)
      diff_minutes <= 30 and diff_minutes > 0 ->
        "font-bold text-red-700 bg-red-100 px-2 py-1 rounded border-red-300 border text-sm"

      # Soon (1 hour or less)
      diff_minutes <= 60 and diff_minutes > 0 ->
        "font-medium text-orange-600 bg-orange-50 px-2 py-1 rounded text-sm"

      # Future events
      true ->
        "text-gray-600 text-sm"
    end
  end
end
