defmodule TbTips.Clans do
  @moduledoc """
  The Clans context.
  """

  import Ecto.Query, warn: false
  alias TbTips.Repo
  alias TbTips.Clans.Clan
  alias TbTips.ClanMemberships

  def list_clans do
    Repo.all(Clan)
  end

  def get_clan!(id), do: Repo.get!(Clan, id)
  def get_clan(id), do: Repo.get(Clan, id)

  @doc """
  Get clan by invite key
  """
  def get_clan_by_invite_key(invite_key) do
    Repo.get_by(Clan, invite_key: invite_key)
  end

  def create_clan(attrs \\ %{}, user) do
    Repo.transact(fn ->
      with {:ok, clan} <- %Clan{} |> Clan.changeset(attrs) |> Repo.insert(),
           {:ok, _membership} <- ClanMemberships.create_clan_membership(user, clan, :admin) do
        {:ok, clan}
      else
        {:error, changeset} -> {:error, changeset}
      end
    end)
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

  @doc """
  Regenerate invite key for a clan (admin only)
  """
  def regenerate_invite_key(clan_id, admin_user_id) do
    alias TbTips.ClanMemberships

    if ClanMemberships.has_clan_role?(admin_user_id, clan_id, :admin) do
      clan = get_clan!(clan_id)
      new_key = generate_random_key()

      clan
      |> Clan.changeset(%{invite_key: new_key})
      |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Get invite key for a clan (admin only)
  """
  def get_invite_key(clan_id, user_id) do
    if ClanMemberships.has_clan_role?(user_id, clan_id, :admin) do
      case get_clan(clan_id) do
        nil -> {:error, :not_found}
        clan -> {:ok, clan.invite_key}
      end
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Generate full invite URL for a clan
  """
  def get_invite_url(clan, base_url \\ "https://tbtips.com") do
    "#{base_url}/join/#{clan.invite_key}"
  end

  @doc """
  Track invite usage (optional - for analytics)
  """
  def log_invite_usage(invite_key, user_id) do
    # You could add an invite_logs table to track who uses which invites
    # For now, just log it
    require Logger
    Logger.info("Invite key #{invite_key} used by user #{user_id}")
    :ok
  end

  # Private helper to generate random keys
  defp generate_random_key do
    :crypto.strong_rand_bytes(16)
    |> Base.url_encode64()
    |> String.replace(["+", "/", "="], "")
    |> String.slice(0, 12)
  end
end
