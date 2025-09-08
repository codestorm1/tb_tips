defmodule TbTips.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias TbTips.Repo
  alias TbTips.Accounts.User
  alias TbTips.Accounts.ClanMembership
  alias TbTips.Accounts.UserToken
  alias TbTips.Accounts.UserNotifier

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.email_changeset(attrs)
    |> Repo.insert()
  end

  ## Settings

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `TbTips.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `TbTips.Accounts.User.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns a tuple with the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Gets the user with the given magic link token.
  """
  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Logs the user in by magic link.

  There are three cases to consider:

  1. The user has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The user has not confirmed their email and no password is set.
     In this case, the user gets confirmed, logged in, and all tokens -
     including session ones - are expired. In theory, no other tokens
     exist but we delete all of them for best security practices.

  3. The user has not confirmed their email but a password is set.
     This cannot happen in the default implementation but may be the
     source of security pitfalls. See the "Mixing magic link and password registration" section of
     `mix help phx.gen.auth`.
  """
  def login_user_by_magic_link(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      # Prevent session fixation attacks by disallowing magic links for unconfirmed users with password
      {%User{confirmed_at: nil, hashed_password: hash}, _token} when not is_nil(hash) ->
        raise """
        magic link log in is not allowed for unconfirmed users with a password set!

        This cannot happen with the default implementation, which indicates that you
        might have adapted the code to a different use case. Please make sure to read the
        "Mixing magic link and password registration" section of `mix help phx.gen.auth`.
        """

      {%User{confirmed_at: nil} = user, _token} ->
        user
        |> User.confirm_changeset()
        |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, {user, []}}

      nil ->
        {:error, :not_found}
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Delivers the magic link login instructions to the given user.
  """
  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {user, tokens_to_expire}}
      end
    end)
  end

  @doc """
  Join a clan using an invite key
  """
  def join_clan_with_invite_key(user, invite_key) do
    alias TbTips.Clans

    with %TbTips.Clans.Clan{} = clan <- Clans.get_clan_by_invite_key(invite_key),
         {:ok, membership} <- create_clan_membership(user, clan, :member) do
      {:ok, membership}
    else
      nil -> {:error, :invalid_invite_key}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Create a clan membership
  """
  def create_clan_membership(user, clan, role \\ :member) do
    %ClanMembership{}
    |> ClanMembership.changeset(%{
      user_id: user.id,
      clan_id: clan.id,
      role: role,
      joined_at: DateTime.utc_now()
    })
    |> Repo.insert()
  end

  @doc """
  Get user's membership in a specific clan
  """
  def get_clan_membership(user_id, clan_id) do
    Repo.get_by(ClanMembership, user_id: user_id, clan_id: clan_id)
  end

  @doc """
  Check if user has a specific role in clan
  """
  def has_clan_role?(user_id, clan_id, required_role) do
    case get_clan_membership(user_id, clan_id) do
      nil -> false
      membership -> role_sufficient?(membership.role, required_role)
    end
  end

  @doc """
  Check if a role meets the minimum requirement
  admin > editor > member
  """
  def role_sufficient?(user_role, required_role) do
    role_hierarchy = %{member: 1, editor: 2, admin: 3}
    role_hierarchy[user_role] >= role_hierarchy[required_role]
  end

  @doc """
  Update user's role in clan (only admins can do this)
  """
  def update_clan_role(admin_user_id, target_user_id, clan_id, new_role) do
    with true <- has_clan_role?(admin_user_id, clan_id, :admin),
         %ClanMembership{} = membership <- get_clan_membership(target_user_id, clan_id) do
      # Prevent demoting the last admin
      if membership.role == :admin and new_role != :admin do
        case count_clan_admins(clan_id) do
          1 -> {:error, :cannot_demote_last_admin}
          _ -> update_membership_role(membership, new_role)
        end
      else
        update_membership_role(membership, new_role)
      end
    else
      false -> {:error, :unauthorized}
      nil -> {:error, :membership_not_found}
    end
  end

  defp update_membership_role(membership, new_role) do
    membership
    |> ClanMembership.changeset(%{role: new_role})
    |> Repo.update()
  end

  defp count_clan_admins(clan_id) do
    from(cm in ClanMembership,
      where: cm.clan_id == ^clan_id and cm.role == :admin,
      select: count(cm.id)
    )
    |> Repo.one()
  end

  @doc """
  List all members of a clan with their roles
  """
  def list_clan_members(clan_id) do
    from(cm in ClanMembership,
      join: u in assoc(cm, :user),
      where: cm.clan_id == ^clan_id,
      select: %{
        user_id: u.id,
        email: u.email,
        role: cm.role,
        joined_at: cm.joined_at
      },
      order_by: [desc: cm.role, asc: cm.joined_at]
    )
    |> Repo.all()
  end

  @doc """
  Remove user from clan
  """
  def leave_clan(user_id, clan_id) do
    case get_clan_membership(user_id, clan_id) do
      nil ->
        {:error, :not_a_member}

      membership ->
        # Prevent last admin from leaving
        if membership.role == :admin and count_clan_admins(clan_id) == 1 do
          {:error, :cannot_leave_as_last_admin}
        else
          Repo.delete(membership)
        end
    end
  end

  @doc """
  Get user's clans with their roles
  """
  def list_user_clans(user_id) do
    from(cm in ClanMembership,
      join: c in assoc(cm, :clan),
      where: cm.user_id == ^user_id,
      select: %{
        clan: c,
        role: cm.role,
        joined_at: cm.joined_at
      },
      order_by: [desc: cm.role, asc: c.name]
    )
    |> Repo.all()
  end
end
