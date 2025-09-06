defmodule TbTipsWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :tb_tips

  @session_options [
    store: :cookie,
    key: "_tb_tips_key",
    # replace with your real salt if you have one
    signing_salt: "change_me",
    same_site: "Lax"
  ]

  # LiveView websocket with session
  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Serve static assets from priv/static
  plug Plug.Static,
    at: "/",
    from: :tb_tips,
    gzip: false,
    # -> must include "assets"
    only: TbTipsWeb.static_paths()

  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :tb_tips
    plug Phoenix.LiveReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session, @session_options

  plug TbTipsWeb.Router
end
