defmodule TbTipsWeb.PageController do
  use TbTipsWeb, :controller

  def home(conn, _params) do
    if conn.assigns[:current_scope] do
      redirect(conn, to: ~p"/dashboard")
    else
      render(conn, :landing)
    end
  end

  def join_redirect(conn, %{"invite_key" => invite_key}) do
    cleaned_key = String.trim(invite_key) |> String.upcase()
    redirect(conn, to: ~p"/join/#{cleaned_key}")
  end
end
