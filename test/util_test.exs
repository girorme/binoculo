defmodule UtilTest do
  use ExUnit.Case, async: true

  alias Binoculo.Util

  test "should parse range or subnet based on user input" do
    input = %{
      :common => "192.168.0.1",
      :cidr => "192.168.0.1/24",
      :range => "192.168.0.1..192.168.0.255",
      :invalid => "192.168.0.x"
    }

    {:ok, subnet_common} = Util.parse_range_or_cidr_notation(input.common)
    {:ok, subnet} = Util.parse_range_or_cidr_notation(input.cidr)
    {:ok, range} = Util.parse_range_or_cidr_notation(input.range)

    assert IP.Subnet = subnet.__struct__
    assert IP.Subnet = subnet_common.__struct__
    assert IP.Range = range.__struct__
    assert {:error, _} = Util.parse_range_or_cidr_notation(input.invalid)
  end
end
