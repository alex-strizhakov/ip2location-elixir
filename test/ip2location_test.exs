defmodule IP2LocationTest do
  use ExUnit.Case

  @test_ip "12.166.16.221"
  @test_location %IP2Location.Record{
    country_short: "US", country_long: "United States", region: "Indiana",
    city: "Indianapolis", latitude: 39.76837921142578, longitude: -86.15804290771484, zipcode: "46201",
    timezone: "-04:00", isp: "AT&T Services Inc.", domain: "att.net", netspeed: "DSL", idd_code: "1",
    area_code: "317/765", weatherstation_code: "USIN0305", weatherstation_name: "Indianapolis", mcc: "310",
    mnc: "030/070/150/170/410/560/680", mobile_brand: "AT&T", elevation: 218.0, usage_type: "ISP/MOB",
    ip_from: 212209664, ip_to: 212209920
  }

  # Needs sample database in etc/db folder
  test "that it works somewhat" do
    db = IP2Location.open_database!(File.cwd! <> "/etc/db/db24-sample.bin")
    assert IP2Location.query(db, @test_ip) == @test_location
  end
end
