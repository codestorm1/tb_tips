# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     TbTips.Repo.insert!(%TbTips.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias TbTips.Repo
alias TbTips.Accounts.User
alias TbTips.Accounts.ClanMembership
alias TbTips.Clans.Clan
alias TbTips.Events.Event

# Clear existing data (optional - comment out if you want to keep existing data)
Repo.delete_all(Event)
Repo.delete_all(ClanMembership)
Repo.delete_all(Clan)
Repo.delete_all(User)

IO.puts("Creating users...")

# Create test users
user1 =
  Repo.insert!(%User{
    email: "alice@example.com",
    display_name: "Alice",
    confirmed_at: DateTime.utc_now()
  })

user2 =
  Repo.insert!(%User{
    email: "bob@example.com",
    display_name: "Bob",
    confirmed_at: DateTime.utc_now()
  })

user3 =
  Repo.insert!(%User{
    email: "charlie@example.com",
    display_name: "Charlie",
    confirmed_at: DateTime.utc_now()
  })

IO.puts("Created #{Repo.aggregate(User, :count)} users")

IO.puts("Creating clans from CSV...")

# Read and parse clans.csv
clans_csv = File.read!("priv/repo/clans.csv")

clans_data =
  clans_csv
  |> String.split("\n", trim: true)
  # Skip header
  |> Enum.drop(1)
  |> Enum.map(fn line ->
    [kingdom, abbr, name] = String.split(line, ",", parts: 3)

    %{
      kingdom: String.trim(kingdom),
      abbr: String.trim(abbr),
      name: String.trim(name)
    }
  end)

# Create all clans from the CSV
clans =
  Enum.with_index(clans_data, 1)
  |> Enum.map(fn {clan_data, index} ->
    Repo.insert!(%Clan{
      name: clan_data.name,
      abbr: clan_data.abbr,
      kingdom: clan_data.kingdom,
      invite_key: "#{clan_data.abbr}#{clan_data.kingdom}_#{index}"
    })
  end)

# Assign some clans for easy reference
[clan1, clan2, clan3 | _rest] = clans

IO.puts("Created #{Repo.aggregate(Clan, :count)} clans")

IO.puts("Creating clan memberships...")

# Create memberships
# Alice is admin of Dragons of War and member of Phoenix Rising
Repo.insert!(%ClanMembership{
  user_id: user1.id,
  clan_id: clan1.id,
  role: :admin
})

Repo.insert!(%ClanMembership{
  user_id: user1.id,
  clan_id: clan2.id,
  role: :member
})

# Bob is admin of Phoenix Rising and editor of Dragons of War
Repo.insert!(%ClanMembership{
  user_id: user2.id,
  clan_id: clan2.id,
  role: :admin
})

Repo.insert!(%ClanMembership{
  user_id: user2.id,
  clan_id: clan1.id,
  role: :editor
})

# Charlie is admin of Shadow Wolves and member of Dragons of War
Repo.insert!(%ClanMembership{
  user_id: user3.id,
  clan_id: clan3.id,
  role: :admin
})

Repo.insert!(%ClanMembership{
  user_id: user3.id,
  clan_id: clan1.id,
  role: :member
})

IO.puts("Created #{Repo.aggregate(ClanMembership, :count)} memberships")

IO.puts("Creating events...")

# Helper function to create events at specific reset offsets
create_event = fn clan, _user, event_type, days_from_now, hours_offset, description ->
  # Calculate start time
  # Reset is at 10am Pacific (UTC-7 or UTC-8 depending on DST)
  # For simplicity, we'll use a fixed offset
  # 10am Pacific = 5pm UTC (approximate)
  reset_hour = 17

  start_time =
    DateTime.utc_now()
    |> DateTime.add(days_from_now * 24 * 60 * 60, :second)
    |> DateTime.add(hours_offset * 60 * 60, :second)
    |> then(fn dt ->
      %{dt | hour: reset_hour, minute: 0, second: 0, microsecond: {0, 6}}
    end)

  %Event{
    event_type: event_type,
    start_time: start_time,
    description: description,
    clan_id: clan.id
  }
end

# Dragons of War events
Repo.insert!(
  create_event.(
    clan1,
    user1,
    "Tinman",
    0,
    4,
    "Don't forget to rally! Targeting K108"
  )
)

Repo.insert!(
  create_event.(
    clan1,
    user2,
    "CP Run",
    1,
    2,
    "Full clan participation required"
  )
)

Repo.insert!(
  create_event.(
    clan1,
    user1,
    "Tinman",
    2,
    6,
    "Saturday morning raid"
  )
)

Repo.insert!(
  create_event.(
    clan1,
    user1,
    "CP Run",
    3,
    1,
    nil
  )
)

# Phoenix Rising events
Repo.insert!(
  create_event.(
    clan2,
    user2,
    "Tinman",
    0,
    8,
    "Evening attack - be online!"
  )
)

Repo.insert!(
  create_event.(
    clan2,
    user1,
    "CP Run",
    1,
    5,
    "Coordinate with allies"
  )
)

Repo.insert!(
  create_event.(
    clan2,
    user2,
    "Tinman",
    4,
    3,
    "Week ahead planning"
  )
)

# Shadow Wolves events
Repo.insert!(
  create_event.(
    clan3,
    user3,
    "CP Run",
    1,
    0,
    "Right at reset - be ready!"
  )
)

Repo.insert!(
  create_event.(
    clan3,
    user3,
    "Tinman",
    2,
    4,
    nil
  )
)

# Some past events for testing
Repo.insert!(
  create_event.(
    clan1,
    user1,
    "Tinman",
    -1,
    2,
    "Yesterday's event"
  )
)

IO.puts("Created #{Repo.aggregate(Event, :count)} events")

IO.puts("""

✅ Seeds completed!

Test users created:
- alice@example.com (Alice)
- bob@example.com (Bob)
- charlie@example.com (Charlie)

Clans created: #{length(clans)} clans from K160 and K168
First 3 clans:
#{Enum.map_join(Enum.take(clans, 3), "\n", fn c -> "- #{c.name} (K#{c.kingdom}-#{c.abbr}) - invite: #{c.invite_key}" end)}

Use magic link authentication to log in as any of these users.
""")
