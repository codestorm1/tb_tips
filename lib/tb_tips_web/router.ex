defmodule TbTipsWeb.Router do
  use TbTipsWeb, :router

  import TbTipsWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TbTipsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TbTipsWeb do
    pipe_through :browser

    get "/", PageController, :home

    live_session :public_with_scope,
      on_mount: [{TbTipsWeb.UserAuth, :mount_current_scope}] do
      live "/clans", ClanLive.Index, :index
      live "/clans/new", ClanLive.Form, :new
      live "/clans/:clan_slug", ClanLive.Show, :show
      live "/clans/:clan_slug/edit", ClanLive.Form, :edit
      live "/clans/:clan_slug/events", EventLive.Index, :index
      live "/clans/:clan_slug/schedule", EventLive.Index, :public
      live "/clans/:clan_slug/events/new", EventLive.Form, :new
      live "/clans/:clan_slug/events/:id", EventLive.Show, :show
      live "/clans/:clan_slug/events/:id/edit", EventLive.Form, :edit
      live "/clans/:clan_slug/invites", ClanLive.ManageInvites, :show
    end
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

  ## Authentication routes

  scope "/", TbTipsWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{TbTipsWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
      live "/join/:invite_key", ClanLive.Join, :show
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  scope "/", TbTipsWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{TbTipsWeb.UserAuth, :require_authenticated}] do
      live "/dashboard", DashboardLive, :index
      live "/clans/new", ClanLive.Form, :new
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end
end
