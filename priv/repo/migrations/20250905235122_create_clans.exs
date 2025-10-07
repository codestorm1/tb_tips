defmodule TbTips.Repo.Migrations.CreateClans do
  use Ecto.Migration

  def change do
    create table(:clans) do
      add :kingdom, :string, null: false
      add :abbr, :string, null: false
      add :name, :string, null: false
      add :invite_key, :string

      timestamps()
    end

    create unique_index(:clans, [:kingdom, :abbr])
    create index(:clans, ["lower(name)"])

    execute("""
    ALTER TABLE clans
      ADD CONSTRAINT clans_abbr_len_chk
      CHECK (char_length(abbr) BETWEEN 1 AND 4)
    """)
  end
end
