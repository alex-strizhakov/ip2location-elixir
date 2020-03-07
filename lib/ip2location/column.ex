defmodule IP2Location.Column do
  @moduledoc false

  use Bitwise, skip_operators: true

  @column_position_map %{
    country: [0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2],
    region: [0, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3],
    city: [0, 0, 0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4],
    isp: [0, 0, 3, 0, 5, 0, 7, 5, 7, 0, 8, 0, 9, 0, 9, 0, 9, 0, 9, 7, 9, 0, 9, 7, 9],
    latitude: [0, 0, 0, 0, 0, 5, 5, 0, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5],
    longitude: [0, 0, 0, 0, 0, 6, 6, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6],
    domain: [0, 0, 0, 0, 0, 0, 0, 6, 8, 0, 9, 0, 10, 0, 10, 0, 10, 0, 10, 8, 10, 0, 10, 8, 10],
    zipcode: [0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 7, 7, 7, 0, 7, 7, 7, 0, 7, 0, 7, 7, 7, 0, 7],
    timezone: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 8, 7, 8, 8, 8, 7, 8, 0, 8, 8, 8, 0, 8],
    netspeed: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 11, 0, 11, 8, 11, 0, 11, 0, 11, 0, 11],
    idd_code: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 12, 0, 12, 0, 12, 9, 12, 0, 12],
    area_code: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 13, 0, 13, 0, 13, 10, 13, 0, 13],
    weatherstation_code: [
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      9,
      14,
      0,
      14,
      0,
      14,
      0,
      14
    ],
    weatherstation_name: [
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      10,
      15,
      0,
      15,
      0,
      15,
      0,
      15
    ],
    mcc: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 16, 0, 16, 9, 16],
    mnc: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 17, 0, 17, 10, 17],
    mobile_brand: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11, 18, 0, 18, 11, 18],
    elevation: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11, 19, 0, 19],
    usage_type: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12, 20]
  }

  @column_type_map %{
    country: :country,
    region: :string,
    city: :string,
    isp: :string,
    latitude: :float,
    longitude: :float,
    domain: :string,
    zipcode: :string,
    timezone: :string,
    netspeed: :string,
    idd_code: :string,
    area_code: :string,
    weatherstation_code: :string,
    weatherstation_name: :string,
    mcc: :string,
    mnc: :string,
    mobile_brand: :string,
    usage_type: :string,
    elevation: :float_string
  }

  @unavailable_value nil
  @empty_value_map %{
    country: {@unavailable_value, @unavailable_value},
    string: @unavailable_value,
    float: 0.0,
    float_string: 0.0
  }

  @read_uint_sizes [8, 32, 128]
  @read_uint_functions Enum.map(@read_uint_sizes, fn size ->
                         {:"read_uint#{size}", 2}
                       end)

  for size <- @read_uint_sizes do
    def unquote(:"read_uint#{size}")(input, offset) do
      <<result::little-unquote(size)>> = binary_part(input, offset - 1, unquote(div(size, 8)))
      result
    end
  end

  def read_string(input, offset) do
    <<length::little-8>> = binary_part(input, offset, 1)
    binary_part(input, offset + 1, length)
  end

  def read_float(input, offset) do
    <<result::float-little-32>> = binary_part(input, offset - 1, 4)
    result
  end

  def read_country_column(input, column_position, row_offset) do
    column_offset = bsl(column_position - 1, 2)
    data_start = read_uint32(input, row_offset + column_offset)
    short_name = read_string(input, data_start)
    long_name = read_string(input, data_start + 3)
    {short_name, long_name}
  end

  def read_string_column(input, column_position, row_offset) do
    column_offset = bsl(column_position - 1, 2)
    data_start = read_uint32(input, row_offset + column_offset)
    read_string(input, data_start)
  end

  def read_float_column(input, column_position, row_offset) do
    column_offset = bsl(column_position - 1, 2)
    read_float(input, row_offset + column_offset)
  end

  def read_float_string_column(input, column_position, row_offset) do
    string = read_string_column(input, column_position, row_offset)

    case Float.parse(string) do
      {value, _rest} -> value
      :error -> 0.0
    end
  end

  @compile {:inline,
            @read_uint_functions ++
              [
                read_string: 2,
                read_float: 2,
                read_country_column: 3,
                read_string_column: 3,
                read_float_column: 3,
                read_float_string_column: 3
              ]}

  for {column_name, positions} <- @column_position_map do
    for {position, db_type} <- Enum.with_index(positions, 1) do
      if position == 0 do
        empty_value = @empty_value_map[@column_type_map[column_name]]

        def read_column(_, unquote(db_type), unquote(column_name), _) do
          unquote(empty_value)
        end
      else
        function_name = :"read_#{@column_type_map[column_name]}_column"

        def read_column(input, unquote(db_type), unquote(column_name), row_offset) do
          unquote(function_name)(input, unquote(position), row_offset)
        end
      end
    end
  end
end
