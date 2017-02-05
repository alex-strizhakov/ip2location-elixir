defmodule IP2Location do
  import IP2Location.Column
  use Bitwise, skip_operators: true

  @moduledoc """
  Interface for accessing IP2Location Binary Format databases.
  This is unstable software, and not officially vetted by IP2Location or anybody else. You have been warned.

  # Implementation details

  This is mostly a port of the [official Erlang library](https://github.com/IP2Location/IP2Location-erlang),
  with three main differences:
  - It uses binary strings instead of charlists (as is common with Elixir libraries)
  - It returns structs instead of records (again, as usual)
  - It accepts the raw binary rather than directly using file IO, giving a very small speed bonus at a massive
    memory cost. This library is therefore almost useless except for regional datasets. Due to how large
    binaries are stored in the BEAM VM heap (using refcounting), once you load a binary database it should
    be safe to send it across processes without memory copying
  """

  @api_version "8.0.3"
  @doc """
    Returns supported API version for binary file
  """
  def api_version do
    @api_version
  end

  defmodule Database do
    @moduledoc """
      Struct for storing a database. It stores the parsed headers and the whole binary
      itself.
    """

    @type t :: %__MODULE__{}
    defstruct [
      :type, :column,
      :ipv4_count, :ipv4_addr, :ipv4_index_addr,
      :ipv6_count, :ipv6_addr, :ipv6_index_addr,
      :ipv4_column_size, :ipv6_column_size,
      :input # raw binary
    ] 
  end

  alias IP2Location.Database

  @doc """
    Parses a database header and returns an struct with all needed settings
    for querying it later.

    Raises ArgumentError if given a invalid raw binary

    ## Examples
    
      iex> raw = File.read!("path/to/database.bin")
      << 5, 6, ...>>

      iex> db = IP2Location.read_database(raw)
      %IP2Location.Database{...}
  """
  def read_database <<
    type::little-8, column::little-8,
    _year::little-8, _month::little-8, _day::little-8,
    ipv4_count::little-32, ipv4_addr::little-32,
    ipv6_count::little-32, ipv6_addr::little-32,
    ipv4_index_addr::little-32, ipv6_index_addr::little-32,
    _::binary >> = input
  do
    %Database{
      type: type, column: column,
      ipv4_count: ipv4_count, ipv4_addr: ipv4_addr,
      ipv6_count: ipv6_count, ipv6_addr: ipv6_addr,
      ipv4_index_addr: ipv4_index_addr,
      ipv6_index_addr: ipv6_index_addr,
      ipv4_column_size: bsl(column, 2),
      ipv6_column_size: 16 + bsl(column - 1, 2),
      input: input
    }
  end

  def read_database(any) do
    raise ArgumentError, message: "Invalid format for database: #{inspect any}"
  end

  @doc """
    Shortcut for loading and parsing a database file.

    Raises if given a invalid raw binary or if there is an error
    reading the file into memory

    ## Examples

      iex> db = IP2Location.open_database!("path/to/database.bin")
      %IP2Location.Database{...}
  """
  def open_database!(file_name) do
    File.read!(file_name) |> read_database()
  end

  defmodule Record do
    @moduledoc """
      Struct representing a record in the location database. Includes all
      fields made available by the database, plus the IP range from where
      the data was found.
    """

    @type t :: %__MODULE__{}
    defstruct [
      area_code: "-", city: "-", country_short: "-",
      country_long: "-", domain: "-", elevation: 0.0, idd_code: "-",
      isp: "-", latitude: 0.0, longitude: 0.0, mcc: "-", mnc: "-",
      mobile_brand: "-", netspeed: "-", region: "-", timezone: "-",
      usage_type: "-", weatherstation_code: "-",
      weatherstation_name: "-", zipcode: "-",
      ip_from: 0, ip_to: 0
    ]
  end

  alias IP2Location.Record

  @base_ipv4_from 281470681743360
	@base_ipv4_to 281474976710655

  @doc """
    Attempts to find a valid entry for a given IP address. If no entry is found
    in the database, it still returns a unitialized struct.

    Returns `{:error, error_message}` if the given IP address is mal-formed.
    
    ## Examples
    
      iex> %IP2Location.Record{city: city} = IP2Location.query(db, "12.166.16.221"); city
      "Indianapolis"
      
      iex> IP2Location.query(db, "not a IP")
      {:error, "Invalid IP address."}
  """
  def query(db = %Database{}, ip) when is_binary(ip),
    do: query(db, to_charlist(ip))
  def query(db = %Database{}, ip) do
    case :inet.parse_address(ip) do
      {:ok, {a, b, c, d}} ->
        ip_number = bsl(a, 24) + bsl(b, 16) + bsl(c, 8) + d
        search(db.input, ip_number, db.type, 0, db.ipv4_count,
          db.ipv4_addr, db.ipv4_index_addr, db.ipv4_column_size, :ipv4)
      
      {:ok, {a, b, c, d, e, f, g, h}} ->
        ip_number = bsl(a, 112) + bsl(b, 96) + bsl(c, 80) + bsl(d, 64) +
           bsl(e, 48) + bsl(f, 32) + bsl(g, 16) + h
        if ip_number >= @base_ipv4_from && ip_number <= @base_ipv4_to do
          search(db.input, ip_number - @base_ipv4_from, db.type, 0,
            db.ipv4_count, db.ipv4_addr, db.ipv4_index_addr,
            db.ipv4_column_size, :ipv4)
        else
          search(db.input, ip_number, db.type, 0, db.ipv6_count,
            db.ipv6_addr, db.ipv6_index_addr, db.ipv6_column_size, :ipv6)
        end
      
      _error ->
        {:error, "Invalid IP address."}
    end
  end

  # {shift, size}
  @ip_type_metadata %{
    ipv4: 32, ipv6: 128
  }

  for {ip_type, size} <- @ip_type_metadata do
    search_tree_function = :"search_tree_#{ip_type}"
    read_function = :"read_uint#{size}"
    extra_offset = if ip_type == :ipv6, do: 12, else: 0

    defp search(input, ip_number, db_type, low, high, base_address, index_base_address, column_size, unquote(ip_type)) do
      if index_base_address > 0 do
        index_position = bsl(bsr(ip_number, unquote(size - 16)), 3) + index_base_address
        better_low = read_uint32(input, index_position)
        better_high = read_uint32(input, index_position + 4)
        unquote(search_tree_function)(input, ip_number, db_type, better_low, better_high, base_address, column_size)
      else
        unquote(search_tree_function)(input, ip_number, db_type, low, high, base_address, column_size)
      end  
    end

    defp unquote(search_tree_function)(input, ip_number, db_type, low, high, base_address, column_size)
      when low <= high
    do
      mid = bsr(low + high, 1)
      row_offset_from = base_address + mid * column_size
      row_offset_to = row_offset_from + column_size
      ip_from = unquote(read_function)(input, row_offset_from)
      ip_to = unquote(read_function)(input, row_offset_to)

      cond do
        ip_number >= ip_from && ip_number < ip_to ->
          read_record(input, db_type + 1, row_offset_from + unquote(extra_offset), ip_from, ip_to)
        ip_number < ip_from ->
          unquote(search_tree_function)(input, ip_number, db_type, low, mid - 1, base_address, column_size)
        true ->
          unquote(search_tree_function)(input, ip_number, db_type, mid + 1, high, base_address, column_size)
      end
    end

    defp unquote(search_tree_function)(_, _, _, _, _, _, _, _), do: %Record{}
  end

  defp read_record(input, type, row_offset, ip_from, ip_to) do
    {country_short, country_long} = read_column(input, type, :country, row_offset)
    
    %Record{
      country_long: country_long,
      country_short: country_short,
      region: read_column(input, type, :region, row_offset),
      city: read_column(input, type, :city, row_offset),
      isp: read_column(input, type, :isp, row_offset),
      latitude: read_column(input, type, :latitude, row_offset),
      longitude: read_column(input, type, :longitude, row_offset),
      domain: read_column(input, type, :domain, row_offset),
      zipcode: read_column(input, type, :zipcode, row_offset),
      timezone: read_column(input, type, :timezone, row_offset),
      netspeed: read_column(input, type, :netspeed, row_offset),
      idd_code: read_column(input, type, :idd_code, row_offset),
      area_code: read_column(input, type, :area_code, row_offset),
      weatherstation_code: read_column(input, type, :weatherstation_code, row_offset),
      weatherstation_name: read_column(input, type, :weatherstation_name, row_offset),
      mcc: read_column(input, type, :mcc, row_offset),
      mnc: read_column(input, type, :mnc, row_offset),
      mobile_brand: read_column(input, type, :mobile_brand, row_offset),
      elevation: read_column(input, type, :elevation, row_offset),
      usage_type: read_column(input, type, :usage_type, row_offset),
      ip_from: ip_from, ip_to: ip_to
    }
  end
end
