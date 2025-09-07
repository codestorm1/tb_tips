defmodule TbTipsWeb.EventLive.Index do
  use TbTipsWeb, :live_view

  alias TbTips.{Events, Clans}
  alias Phoenix.LiveView.JS

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
          <.link navigate={~p"/clans/#{@clan.slug}"} class="btn btn-ghost">← Back to Clan</.link>
        </div>
      </div>

      <section class="mt-6 overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm">
        <!-- header -->
        <div class="grid grid-cols-12 items-center gap-3 bg-gray-50 px-5 py-2.5 text-xs font-medium text-gray-600">
          <div class="col-span-3">Event</div>
          <div class="col-span-5">When</div>
          <div class="col-span-3">Description</div>
          <div class="col-span-1 text-right">Actions</div>
        </div>

        <div class="divide-y divide-gray-200">
          <%= for event <- @events do %>
            <!-- Taller rows to accommodate multi-line description -->
            <div
              id={"event-#{event.id}"}
              class="grid grid-cols-12 items-start gap-3 px-5 py-4 hover:bg-gray-50"
            >
              <!-- Left 11 cols hold the clickable area -->
              <div class="col-span-11 relative min-w-0">
                <!-- Content grid inside: 3/5/3 tracks; min-w-0 allows wrapping without overflow -->
                <div class="grid grid-cols-11 gap-3 relative z-10 min-w-0">
                  <!-- Event -->
                  <div class="col-span-3 min-w-0">
                    <div class="inline-flex items-center rounded-full bg-gray-100 px-2.5 py-1 text-xs font-medium text-gray-800">
                      {event.event_type}
                    </div>
                    <div class="mt-1 text-xs text-gray-500">
                      by <span class="text-gray-800">{event.created_by_name}</span>
                    </div>
                  </div>
                  
    <!-- When: time on first line, city below -->
                  <div class="col-span-5 min-w-0">
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
                  
    <!-- Description: multi-line, bullets if the text uses "* " -->
                  <div class="col-span-3 min-w-0 text-sm text-gray-800">
                    <.description_cell text={event.description} max_lines={8} />
                  </div>
                </div>
                
    <!-- Invisible overlay link to make most of the row clickable -->
                <.link
                  navigate={~p"/clans/#{@clan.slug}/events/#{event.id}"}
                  aria-label={"Open event #{event.id}"}
                  class="absolute inset-0 z-0 block"
                >
                  <span class="sr-only">Open</span>
                </.link>
              </div>
              
    <!-- Actions (kept above the overlay for reliable clicks) -->
              <div class="col-span-1 text-right text-sm relative z-20">
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
  def mount(%{"clan_slug" => slug}, _session, socket) do
    is_admin = socket.assigns.live_action != :public

    case Clans.get_clan_by_slug(slug) do
      nil ->
        {:ok,
         socket
         |> assign(:user_tz, nil)
         |> put_flash(:error, "Clan not found")
         |> redirect(to: ~p"/clans")}

      clan ->
        events = Events.list_events_for_clan(clan.id)

        {:ok,
         socket
         |> assign(:user_tz, nil)
         |> assign(:clan, clan)
         |> assign(:is_admin, is_admin)
         |> assign(:page_title, page_title(is_admin, clan.name))
         |> assign(:events, events)}
    end
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
end
