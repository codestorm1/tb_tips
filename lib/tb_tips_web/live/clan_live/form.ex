defmodule TbTipsWeb.ClanLive.Form do
  use TbTipsWeb, :live_view

  alias TbTips.Clans
  alias TbTips.Clans.Clan

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage clan records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="clan-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:kingdom]} type="text" label="Kingdom" />
        <.input field={@form[:abbr]} type="text" label="Abbreviation" />
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:invite_key]} type="text" label="Invite key" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Clan</.button>
          <.button navigate={return_path(@return_to, @clan)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    case socket.assigns.current_scope do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "You must be logged in to create a clan")
         |> redirect(to: ~p"/users/log-in")}

      %{user: _user} ->
        {:ok,
         socket
         |> assign(:return_to, return_to(params["return_to"]))
         |> apply_action(socket.assigns.live_action, params)}
    end
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    clan = Clans.get_clan!(id)

    socket
    |> assign(:page_title, "Edit Clan")
    |> assign(:clan, clan)
    |> assign(:form, to_form(Clans.change_clan(clan)))
  end

  defp apply_action(socket, :new, _params) do
    clan = %Clan{}

    socket
    |> assign(:page_title, "New Clan")
    |> assign(:clan, clan)
    |> assign(:form, to_form(Clans.change_clan(clan)))
  end

  @impl true
  def handle_event("validate", %{"clan" => clan_params}, socket) do
    changeset = Clans.change_clan(socket.assigns.clan, clan_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"clan" => clan_params}, socket) do
    save_clan(socket, socket.assigns.live_action, clan_params)
  end

  defp save_clan(socket, :edit, clan_params) do
    case Clans.update_clan(socket.assigns.clan, clan_params) do
      {:ok, clan} ->
        {:noreply,
         socket
         |> put_flash(:info, "Clan updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, clan))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_clan(socket, :new, clan_params) do
    case Clans.create_clan(clan_params, socket.assigns.current_scope.user) do
      {:ok, clan} ->
        {:noreply,
         socket
         |> put_flash(:info, "Clan created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, clan))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _clan), do: ~p"/clans"
  defp return_path("show", clan), do: ~p"/clans/#{clan}"
end
