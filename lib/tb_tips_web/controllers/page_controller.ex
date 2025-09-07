defmodule TbTipsWeb.PageController do
  use TbTipsWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: ~p"/clans/K160-COC/schedule")
  end

  # def home(conn, _params) do
  #   render(conn, :home)
  # end
end
