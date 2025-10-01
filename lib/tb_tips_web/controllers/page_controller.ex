defmodule TbTipsWeb.PageController do
  use TbTipsWeb, :controller

  def home(conn, _params) do
    if conn.assigns[:current_scope] do
      redirect(conn, to: ~p"/dashboard")
    else
      render(conn, :landing)
    end
  end
end
