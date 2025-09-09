defmodule TbTips.Repo.Migrations.CreateClanMemberships do
  use Ecto.Migration

  def change do
    create table(:clan_memberships) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :clan_id, references(:clans, on_delete: :delete_all), null: false
      add :role, :string, null: false, default: "member"
      add :joined_at, :utc_datetime_usec, default: fragment("now()")

      timestamps()
    end

    create unique_index(:clan_memberships, [:user_id, :clan_id])
    create index(:clan_memberships, [:clan_id])
    create index(:clan_memberships, [:user_id])
  end
end
