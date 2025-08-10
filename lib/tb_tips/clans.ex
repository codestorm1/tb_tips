defmodule TbTips.Clans do
  @moduledoc """
  The Clans context.
  """

  import Ecto.Query, warn: false
  alias TbTips.Repo
  alias TbTips.Clans.Clan

  def list_clans do
    Repo.all(Clan)
  end

  def get_clan!(id), do: Repo.get!(Clan, id)

  def get_clan_by_slug!(slug), do: Repo.get_by!(Clan, slug: slug)

  def get_clan_by_slug(slug), do: Repo.get_by(Clan, slug: slug)

  def create_clan(attrs \\ %{}) do
    %Clan{}
    |> Clan.changeset(attrs)
    |> Repo.insert()
  end

  def update_clan(%Clan{} = clan, attrs) do
    clan
    |> Clan.changeset(attrs)
    |> Repo.update()
  end

  def delete_clan(%Clan{} = clan) do
    Repo.delete(clan)
  end

  def change_clan(%Clan{} = clan, attrs \\ %{}) do
    Clan.changeset(clan, attrs)
  end
end
