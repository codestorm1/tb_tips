# lib/tb_tips/time/reset_clock.ex
defmodule TbTips.Time.ResetClock do
  @tz "America/Los_Angeles"
  # 10:00 LA, DST-aware
  @reset_local ~T[10:00:00]

  def reset_at_utc(date) do
    {:ok, local} = DateTime.new(date, @reset_local, @tz)
    DateTime.shift_zone!(local, "Etc/UTC")
  end

  def offset_from_start_utc(%DateTime{} = start) do
    start_utc =
      if start.time_zone == "Etc/UTC", do: start, else: DateTime.shift_zone!(start, "Etc/UTC")

    la = DateTime.shift_zone!(start_utc, @tz)
    game_date = DateTime.to_date(la)
    reset_utc = reset_at_utc(game_date)
    DateTime.diff(start_utc, reset_utc, :minute)
  end

  def format_r_label(off) do
    h = div(off, 60)
    m = abs(rem(off, 60))

    base =
      cond do
        h > 0 -> "Reset+#{h}"
        h < 0 -> "Reset#{h}"
        true -> "Reset"
      end

    if m == 0 or off == 0,
      do: base,
      else: base <> ":" <> String.pad_leading(Integer.to_string(m), 2, "0")
  end
end
