defmodule TbTipsWeb.PageController do
  use TbTipsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
