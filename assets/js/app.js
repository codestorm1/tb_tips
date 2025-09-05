// assets/js/app.js — clean, minimal, and safe for a fixed-UTC RESET setup
// Compatible with Phoenix 1.7.x and LiveView 1.1.x

import "phoenix_html"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "topbar"

// ——— Topbar page loading indicator (optional but nice)
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", () => topbar.show())
window.addEventListener("phx:page-loading-stop",  () => topbar.hide())

// ——— LiveView Hooks
const Hooks = {}

// Send the browser IANA timezone to the server once. Useful when you
// want to render *server-side* local times (while your RESET remains fixed UTC).
Hooks.TzSender = {
  mounted() {
    try {
      const tz = Intl.DateTimeFormat().resolvedOptions().timeZone
      this.pushEvent("tz", { tz })
    } catch (_e) {
      // no-op
    }
  }
}

// OPTIONAL: If you prefer *client-side* formatting of UTC datetimes, attach
// phx-hook="LocalTime" to an element with data-utc="<ISO8601 UTC>".
Hooks.LocalTime = {
  mounted() { this.render() },
  updated() { this.render() },
  render() {
    const iso = this.el.dataset.utc
    if (!iso) return
    const dt = new Date(iso)
    if (isNaN(dt)) return

    // Example format: "Mon 08/23/2025, 12:34"
    const opts = {
      weekday: "short",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit"
    }

    this.el.textContent = dt.toLocaleString(undefined, opts)
    this.el.title = `${iso} (UTC)`
  }
}

// OPTIONAL: Live countdown to a UTC instant in data-utc
Hooks.EventCountdown = {
  mounted() {
    this.timer = setInterval(() => this.render(), 1000)
    this.render()
  },
  destroyed() { clearInterval(this.timer) },
  render() {
    const iso = this.el.dataset.utc
    if (!iso) return
    const target = new Date(iso).getTime()
    if (isNaN(target)) return

    const now = Date.now()
    let diff = Math.max(0, Math.floor((target - now) / 1000))

    const days = Math.floor(diff / 86400); diff -= days * 86400
    const hours = Math.floor(diff / 3600); diff -= hours * 3600
    const minutes = Math.floor(diff / 60); diff -= minutes * 60
    const seconds = diff

    const pad = n => n.toString().padStart(2, "0")
    this.el.textContent = days > 0
      ? `${days}d ${pad(hours)}h ${pad(minutes)}m ${pad(seconds)}s`
      : `${hours}h ${pad(minutes)}m ${pad(seconds)}s`
  }
}

// ——— LiveSocket bootstrap
let csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks
})

// Connect if there are any LiveViews on the page
liveSocket.connect()

// Expose for debug (
//   window.liveSocket.enableDebug(),
//   window.liveSocket.disableDebug(),
//   document.addEventListener("phx:page-loading-start", ...)
// )
window.liveSocket = liveSocket
