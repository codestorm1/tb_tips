defmodule TbTips.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :description, :text
      add :start_time, :utc_datetime
      add :event_type, :string
      add :created_by_name, :string
      add :clan_id, references(:clans, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:events, [:clan_id])
  end
end
