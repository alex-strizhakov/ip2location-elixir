# IP2Location-Elixir

Interface for accessing IP2Location Binary Format databases.
**This is unstable software, and not officially vetted by IP2Location or anybody else.** You have been warned.

## Implementation details

This is mostly a port of the [official Erlang library](https://github.com/IP2Location/IP2Location-erlang),
with three main differences:
- It uses binary strings instead of charlists (as is common with Elixir libraries).
- It returns structs instead of records (again, as usual).
- It accepts the raw binary rather than directly using file IO, giving a very small speed bonus at a massive
  memory cost. This library is therefore almost useless except for regional databases. Due to how large
  binaries are stored in the BEAM VM heap (using refcounting), once you load a binary database it should
  be safe to send it across processes without memory copying.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ip2location_elixir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:ip2location_elixir, "~> 0.1.0"}]
end
```

## Usage

```elixir
# Load your file
raw = File.read!("path/to/database.bin")

# Prepare headers for use
db = IP2Location.read_database(raw) 

# Alternatively you can just use the `open_database!/1` shortcut
# db = IP2Location.open_database!("path/to/database.bin") 

# Grab your stuff
%IP2Location.Record{city: city} = IP2Location.query(db, "some IP")
```

## License
See [LICENSE](LICENSE)
