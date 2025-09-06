defmodule TbTips.Time.ResetClock do
  @moduledoc "TB RESET anchored to a fixed UTC time. No DST."
  def reset_time_utc,
    do:
      (
        cfg = Application.get_env(:tb_tips, :reset_utc, hour: 18, minute: 0)
        elem(Time.new(cfg[:hour], cfg[:minute], 0), 1)
      )

  def reset_at_utc(date) do
    {:ok, dt} = DateTime.new(date, reset_time_utc(), "Etc/UTC")
    dt
  end

  # Minutes since the most recent RESET before/at start_utc
  def offset_from_start_utc(%DateTime{} = start) do
    start_utc = (start.time_zone == "Etc/UTC" && start) || DateTime.shift_zone!(start, "Etc/UTC")
    date = DateTime.to_date(start_utc)

    base_date =
      if Time.compare(DateTime.to_time(start_utc), reset_time_utc()) == :lt,
        do: Date.add(date, -1),
        else: date

    DateTime.diff(start_utc, reset_at_utc(base_date), :minute)
  end

  def format_r_label(off) do
    h = div(off, 60)
    m = abs(rem(off, 60))

    base =
      cond do
        h > 0 -> "R+#{h}"
        h < 0 -> "R#{h}"
        true -> "R"
      end

    if m == 0 or off == 0,
      do: base,
      else: base <> ":" <> String.pad_leading(Integer.to_string(m), 2, "0")
  end
end
