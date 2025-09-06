defmodule TbTipsWeb.Router do
  use TbTipsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TbTipsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TbTipsWeb do
    pipe_through :browser

    get "/", PageController, :home

    live "/clans", ClanLive.Index, :index
    live "/clans/new", ClanLive.Form, :new
    live "/clans/:clan_slug", ClanLive.Show, :show
    live "/clans/:clan_slug/edit", ClanLive.Form, :edit

    live "/clans/:clan_slug/events", EventLive.Index, :index
    # list view without edit controls
    live "/clans/:clan_slug/schedule", EventLive.Index, :public
    live "/clans/:clan_slug/events/new", EventLive.Form, :new
    live "/clans/:clan_slug/events/:id", EventLive.Show, :show
    live "/clans/:clan_slug/events/:id/edit", EventLive.Form, :edit
  end

  # Other scopes may use custom stacks.
  # scope "/api", TbTipsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:tb_tips, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TbTipsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
