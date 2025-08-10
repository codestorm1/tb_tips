defmodule TbTips.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :title, :string, null: false
      add :description, :text
      add :start_time, :utc_datetime, null: false
      add :event_type, :string, null: false, default: "Custom"
      add :created_by_name, :string
      add :clan_id, references(:clans, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:events, [:clan_id])
    create index(:events, [:start_time])
    create index(:events, [:event_type])
  end
end
