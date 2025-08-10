defmodule TbTips.Repo do
  use Ecto.Repo,
    otp_app: :tb_tips,
    adapter: Ecto.Adapters.Postgres
end
