// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/tb_tips"
import topbar from "../vendor/topbar"

// Custom hooks for time display components
const Hooks = {
LocalTime: {
  mounted() {
    this.updateLocalTime()
  },
  updated() {
    this.updateLocalTime()
  },
  updateLocalTime() {
    const utcTime = this.el.dataset.utc
    if (utcTime) {
      try {
        const date = new Date(utcTime)
        const options = {
          weekday: 'short',
          month: 'short', 
          day: 'numeric',
          hour: 'numeric',
          minute: '2-digit',
          timeZoneName: 'short'  // Add this line
        }
        this.el.textContent = date.toLocaleDateString('en-US', options)
      } catch (e) {
        this.el.textContent = "Invalid date"
      }
    }
  }
},

  EventCountdown: {
    mounted() {
      this.startCountdown()
    },
    updated() {
      this.startCountdown()
    },
    destroyed() {
      if (this.interval) {
        clearInterval(this.interval)
      }
    },
    startCountdown() {
      const utcTime = this.el.dataset.utc
      if (utcTime) {
        try {
          const targetDate = new Date(utcTime)
          
          const updateCountdown = () => {
            const now = new Date()
            const diff = targetDate - now
            
            if (diff <= 0) {
              this.el.textContent = "Event started!"
              return
            }
            
            const days = Math.floor(diff / (1000 * 60 * 60 * 24))
            const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
            const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))
            
            if (days > 0) {
              this.el.textContent = `${days}d ${hours}h ${minutes}m`
            } else if (hours > 0) {
              this.el.textContent = `${hours}h ${minutes}m`
            } else {
              this.el.textContent = `${minutes}m`
            }
          }
          
          updateCountdown()
          this.interval = setInterval(updateCountdown, 60000) // Update every minute
        } catch (e) {
          this.el.textContent = "Invalid date"
        }
      }
    }
  },

  TimePreview: {
    mounted() {
      this.initializeTimePreview()
    },
    updated() {
      this.initializeTimePreview()
    },
    initializeTimePreview() {
      // This hook can be used for form time previews if needed
      // Currently just a placeholder for future functionality
    }
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, ...Hooks},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}