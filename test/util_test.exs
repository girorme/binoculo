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
    assert {:error, _} = Util.parse_range_or_cidr_notation("192.168.0.10..192.168.0.1")
  end

  test "should get app version" do
    assert is_binary(Util.version())
  end

  test "should return banner and version" do
    assert Util.banner() =~ ~r/#{Util.version()}/
  end

  describe "format_duration/1" do
    test "should format milliseconds, seconds, minutes and hours" do
      assert "0ms" == Util.format_duration(0)
      assert "850ms" == Util.format_duration(850)
      assert "1.0s" == Util.format_duration(1000)
      assert "42.1s" == Util.format_duration(42_100)
      assert "1m 0.0s" == Util.format_duration(59_960)
      assert "3m 42.1s" == Util.format_duration(222_100)
      assert "1h 2m 3.0s" == Util.format_duration(3_723_000)
      assert "26m 45.0s" == Util.format_duration(1_605_000)
    end
  end

  test "should format the current datetime as ISO 8601 with offset" do
    assert Util.format_datetime() =~ ~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}([+-]\d{2}:\d{2}|Z)$/
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

  test "should return a map when valid response is passed only with header" do
    header =
      "HTTP/1.0 302 Moved Temporarily\r\nDate: Sat, 06 Jan 2024 15:55:33 GMT\r\nServer: Boa/0.93.15\r\nX-Frame-Options: SAMEORIGIN\r\nConnection: close\r\nContent-Type: text/html"

    assert is_map(Util.format_http_response(header))
  end

  describe "format_error_line/3" do
    test "should hint to raise the timeout, in yellow, on connect/timeout" do
      System.delete_env("NO_COLOR")
      line = Util.format_error_line({:connect, :timeout, 32_132}, 500, 500)

      assert line =~ "connect/timeout"
      assert line =~ "32132"
      assert line =~ "--timeout <ms> - now: 500ms, default: 500ms"
      assert line =~ IO.ANSI.yellow()
      assert line =~ IO.ANSI.reset()
    end

    test "should not use colors when NO_COLOR is set" do
      System.put_env("NO_COLOR", "1")
      on_exit(fn -> System.delete_env("NO_COLOR") end)

      line = Util.format_error_line({:connect, :timeout, 5}, 500, 500)
      assert line =~ "try increasing the timeout"
      refute line =~ "\e["
    end

    test "should not add a hint to other errors" do
      assert "      connect/econnrefused         7" ==
               Util.format_error_line({:connect, :econnrefused, 7}, 500, 500)
    end
  end

  test "should not crash on headers without a space after the colon or without a colon" do
    header =
      "HTTP/1.1 200 OK\r\nX-XSS-Protection:1; mode=block\r\nServer: nginx\r\nbroken line\r\n\r\n"

    assert %{
             "Code" => "HTTP/1.1 200 OK",
             "X-XSS-Protection" => "1; mode=block",
             "Server" => "nginx"
           } == Util.format_http_response(header)
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
