defmodule TbTips.Time.ResetClock do
  @moduledoc """
  TB RESET anchored to a fixed UTC time (no DST).
  - Game day boundary: {hour, minute} UTC, same every day.
  - Provides helpers to compute R± offsets/labels.
  """

  @spec reset_time_utc() :: Time.t()
  def reset_time_utc do
    cfg = Application.get_env(:tb_tips, :reset_utc, hour: 18, minute: 0)
    {:ok, t} = Time.new(cfg[:hour], cfg[:minute], 0)
    t
  end

  @doc "RESET instant in UTC for the given *game date* (UTC calendar date)."
  @spec reset_at_utc(Date.t()) :: DateTime.t()
  def reset_at_utc(date) do
    {:ok, dt} = DateTime.new(date, reset_time_utc(), "Etc/UTC")
    dt
  end

  @doc "Given a UTC start time, compute minutes since the most recent UTC RESET."
  @spec offset_from_start_utc(DateTime.t()) :: integer()
  def offset_from_start_utc(%DateTime{time_zone: "Etc/UTC"} = start) do
    date = DateTime.to_date(start)
    # If event time-of-day is before RESET, the relevant RESET was yesterday
    base_date =
      if Time.compare(start |> DateTime.to_time(), reset_time_utc()) == :lt do
        Date.add(date, -1)
      else
        date
      end

    DateTime.diff(start, reset_at_utc(base_date), :minute)
  end

  def offset_from_start_utc(start),
    do: start |> DateTime.shift_zone!("Etc/UTC") |> offset_from_start_utc()

  @doc "R occurrence in UTC from a given *game date* and offset in minutes."
  @spec r_at_utc(integer(), Date.t()) :: DateTime.t()
  def r_at_utc(offset_minutes, date),
    do: DateTime.add(reset_at_utc(date), offset_minutes * 60, :second)

  @doc "Label minutes as R/R+H/R-H[:MM]."
  @spec format_r_label(integer()) :: String.t()
  def format_r_label(off) do
    h = div(off, 60)
    m = abs(rem(off, 60))

    base =
      cond do
        h > 0 -> "R+#{h}"
        # includes minus
        h < 0 -> "R#{h}"
        true -> "R"
      end

    if m == 0 or off == 0,
      do: base,
      else: base <> ":" <> String.pad_leading(Integer.to_string(m), 2, "0")
  end

  @doc "Parse 'R', 'R+2', 'R-3', 'R+1:30' -> minutes."
  @spec parse_r_label(String.t()) :: {:ok, integer()} | :error
  def parse_r_label(label) do
    with s <- String.upcase(String.trim(label)),
         true <- s == "R" or String.match?(s, ~r/^R[+-]\d{1,2}(:\d{1,2})?$/) do
      case s do
        "R" ->
          {:ok, 0}

        _ ->
          [_, signh, rest] = Regex.run(~r/^R([+-]\d{1,2})(?::(\d{1,2}))?$/, s)
          # includes sign
          h = String.to_integer(signh)
          m = if(rest in [nil, ""], do: 0, else: String.to_integer(rest))
          if m in 0..59, do: {:ok, h * 60 + if(h < 0, do: -m, else: m)}, else: :error
      end
    else
      _ -> :error
    end
  end
end
