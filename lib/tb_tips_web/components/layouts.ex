defmodule TbTipsWeb.Layouts do
  use TbTipsWeb, :html
  embed_templates "layouts/*"

  # --- Stubs used by older templates (e.g., home.html.heex) ---

  def flash_group(assigns) do
    ~H"""
    <%= if msg = Phoenix.Flash.get(@flash, :info) do %>
      <div class="rounded-md bg-blue-50 border border-blue-200 text-blue-900 px-3 py-2 text-sm">
        {msg}
      </div>
    <% end %>
    <%= if msg = Phoenix.Flash.get(@flash, :error) do %>
      <div class="rounded-md bg-red-50 border border-red-200 text-red-900 px-3 py-2 text-sm">
        {msg}
      </div>
    <% end %>
    """
  end

  # simple no-op toggle placeholder; customize later or remove from templates
  def theme_toggle(assigns) do
    ~H"""
    <button type="button" class="text-xs text-gray-500 hover:text-gray-700">Theme</button>
    """
  end
end
