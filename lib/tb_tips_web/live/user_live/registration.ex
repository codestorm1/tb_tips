defmodule TbTipsWeb.UserLive.Registration do
  use TbTipsWeb, :live_view

  alias TbTips.Accounts
  alias TbTips.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <.header>
          Register for an account
          <:subtitle>
            Already registered?
            <.link navigate={~p"/users/log-in"} class="font-semibold text-brand hover:underline">
              Log in
            </.link>
            to your account now.
          </:subtitle>
        </.header>

        <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
          <.input field={@form[:email]} type="email" label="Email" required />
          <.input field={@form[:password]} type="password" label="Password" required />

          <div class="space-y-3 text-sm">
            <.input
              field={@form[:terms_accepted]}
              type="checkbox"
              label={
                raw(
                  "I agree to the <a href='/terms' target='_blank' class='text-blue-600 underline'>Terms and Conditions</a>"
                )
              }
              required
            />
            <.input
              field={@form[:privacy_accepted]}
              type="checkbox"
              label={
                raw(
                  "I agree to the <a href='/privacy' target='_blank' class='text-blue-600 underline'>Privacy Policy</a>"
                )
              }
              required
            />
          </div>

          <.button phx-disable-with="Creating account..." class="btn btn-primary w-full">
            Create an account
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})
    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  @impl true
  # In registration.ex, change the handle_event("save"...) function:
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, _user} ->
        # Instead of magic link, redirect to login with password
        {:noreply,
         socket
         |> put_flash(:info, "Account created successfully! Please log in with your password.")
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
