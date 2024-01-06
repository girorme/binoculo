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

  test "should get app version" do
    assert is_binary(Util.version())
  end

  test "should return banner and version" do
    assert Util.banner() =~ ~r/#{Util.version()}/
  end

  test "should return a map when valid response without header is passed" do
    header = "Just response"
    assert is_map(Util.format_http_response(header))
  end

  test "should return a map when valid response is passed" do
    header =
      "HTTP/1.0 302 Moved Temporarily\r\nDate: Sat, 06 Jan 2024 15:55:33 GMT\r\nServer: Boa/0.93.15\r\nX-Frame-Options: SAMEORIGIN\r\nConnection: close\r\nContent-Type: text/html\r\nLocation: /admin/login.asp\r\n\r\n"

    assert is_map(Util.format_http_response(header))
  end

  test "should return a valid text template from host_info map" do
    host_info = %{
      host: "localhost",
      port: "80",
      response: "ok"
    }

    expected_template = """
    --=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--
    Host: #{host_info[:host]}
    Port: #{host_info[:port]}

    #{host_info[:response]}
    --=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--
    """

    assert expected_template == Util.host_info_to_text_template(host_info)
  end
end
