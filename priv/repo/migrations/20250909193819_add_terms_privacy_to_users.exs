defmodule TbTips.Repo.Migrations.AddTermsPrivacyToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :terms_accepted_at, :utc_datetime
      add :privacy_accepted_at, :utc_datetime
    end
  end
end
