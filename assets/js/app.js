// assets/js/app.js
// Minimal LiveView client with hooks

import "phoenix_html"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"

// ---- Hooks ----
const Hooks = {}

// LocalTime: renders a UTC ISO8601 string (in data-utc) as the user's local time
Hooks.LocalTime = {
  render() {
    const iso = this.el.dataset.utc
    if (!iso) return
    const d = new Date(iso)
    if (isNaN(d)) {
      this.el.textContent = iso
      return
    }
    
    // Format as "Sun, Aug 17 at 3:00 PM"
    const options = {
      weekday: 'short',
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit'
    }
    
    this.el.textContent = d.toLocaleDateString('en-US', options)
  },
  mounted() { this.render() },
  updated() { this.render() }
}

// EventCountdown: shows countdown to a specific event time
Hooks.EventCountdown = {
  mounted() {
    this.updateCountdown()
    this.timer = setInterval(() => {
      this.updateCountdown()
    }, 1000)
  },
  
  destroyed() {
    if (this.timer) {
      clearInterval(this.timer)
    }
  },
  
  updateCountdown() {
    const iso = this.el.dataset.utc
    if (!iso) return
    
    const eventTime = new Date(iso)
    if (isNaN(eventTime)) return
    
    const now = new Date()
    const diff = eventTime.getTime() - now.getTime()
    
    if (diff <= 0) {
      this.el.innerHTML = '<span class="text-red-600 font-bold">🔴 EVENT IS LIVE!</span>'
      return
    }
    
    const days = Math.floor(diff / (1000 * 60 * 60 * 24))
    const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))
    
    let countdown = []
    if (days > 0) countdown.push(`${days} day${days > 1 ? 's' : ''}`)
    if (hours > 0) countdown.push(`${hours} hour${hours > 1 ? 's' : ''}`)
    if (minutes > 0 || countdown.length === 0) countdown.push(`${minutes} minute${minutes > 1 ? 's' : ''}`)
    
    this.el.textContent = countdown.join(', ')
  }
}

// ---- LiveSocket ----
const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content") || ""

const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose for debug/latency simulation in dev console
window.liveSocket = liveSocket
