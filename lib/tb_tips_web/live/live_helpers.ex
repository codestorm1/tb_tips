defmodule TbTipsWeb.LiveHelpers do
  @moduledoc """
  Helper functions for LiveView authorization and clan membership
  """

  import Phoenix.Component
  alias TbTips.Accounts

  @doc """
  Check user authorization for clan actions
  """
  def authorize_clan_action(socket, clan_id, required_role) do
    user = socket.assigns.current_user

    if user && Accounts.has_clan_role?(user.id, clan_id, required_role) do
      {:ok, socket}
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Assign user's role in the current clan to socket
  """
  def assign_user_clan_role(socket, clan_id) do
    case socket.assigns.current_user do
      nil ->
        assign(socket, :user_clan_role, nil)

      user ->
        membership = Accounts.get_clan_membership(user.id, clan_id)
        role = if membership, do: membership.role, else: nil
        assign(socket, :user_clan_role, role)
    end
  end

  @doc """
  Check if user can edit events (admin or editor)
  """
  def can_edit_events?(socket) do
    socket.assigns[:user_clan_role] in [:admin, :editor]
  end

  @doc """
  Check if user is clan admin
  """
  def is_clan_admin?(socket) do
    socket.assigns[:user_clan_role] == :admin
  end

  @doc """
  Render content only if user has required role
  """
  def render_if_role(assigns, required_role, content_fun) do
    user_role = assigns[:user_clan_role]

    if Accounts.role_sufficient?(user_role || :member, required_role) do
      content_fun.()
    else
      ~H""
    end
  end

  @doc """
  Get user-friendly role name
  """
  def role_display_name(:admin), do: "Admin"
  def role_display_name(:editor), do: "Editor"
  def role_display_name(:member), do: "Member"
  def role_display_name(nil), do: "Not a member"
end
