defmodule TbTipsWeb.Components.TimePreview do
  use Phoenix.Component

  def time_preview(assigns) do
    ~H"""
    <div class="time-preview reset-time" id="time-preview">
      <div class="time-preview-label">Reset Time (R+<span id="reset-offset-display">6</span>)</div>
      <div class="time-display">
        <span class="time-value" id="resetTimeDisplay">Tue Aug 13 at 12:00 AM</span>
      </div>
    </div>

    <div class="time-preview local-time">
      <div class="time-preview-label">Your Local Time</div>
      <div class="time-display">
        <span class="time-value" id="localTimeDisplay">Mon Aug 12 at 5:00 PM</span>
        <span class="time-zone">PDT</span>
      </div>
    </div>
    """
  end
end
