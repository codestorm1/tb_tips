defmodule TbTips.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :name, :string
      add :description, :text
      add :start_time, :utc_datetime
      add :event_type, :string
      add :created_by_name, :string
      add :clan_id, references(:clans, on_delete: :nothing)
      add :created_by_user_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:events, [:clan_id])
    create index(:events, [:clan_id, :start_time])
    create index(:events, [:created_by_user_id])
  end
end
