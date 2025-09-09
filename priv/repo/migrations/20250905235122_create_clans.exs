defmodule TbTips.Repo.Migrations.CreateClans do
  use Ecto.Migration

  def change do
    create table(:clans) do
      add :name, :string
      add :slug, :string
      add :kingdom, :string
      add :invite_key, :string

      timestamps(type: :utc_datetime_usec)
    end
  end
end
