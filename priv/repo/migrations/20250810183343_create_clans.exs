defmodule TbTips.Repo.Migrations.CreateClans do
  use Ecto.Migration

  def change do
    create table(:clans) do
      add :slug, :string, null: false
      add :name, :string, null: false
      add :kingdom, :string, null: false
      add :description, :string, null: true
      timestamps()
    end

    create unique_index(:clans, [:slug])
    create index(:clans, [:kingdom])
  end
end
