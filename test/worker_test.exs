defmodule WorkerTest do
  @moduledoc """
  Main worker (get_banner) tests
  """
  use ExUnit.Case, async: true

  alias Binoculo.{Config, Worker}
  alias Binoculo.Stub.Server

  describe "Testing the banner grab function" do
    test "get banner passing ip + port" do
      host_ut = "127.0.0.1"
      port_ut = 21_210
      port_ut_http = 8080

      ftp_pid = spawn(Server, :start, [port_ut, "ftp server"])
      Process.sleep(:timer.seconds(1))

      {:ok, %{response: response, host: host, port: port}} = Worker.get_banner(host_ut, port_ut)

      assert host_ut == host
      assert port_ut == port
      assert response =~ ~r/ftp/i

      Process.exit(ftp_pid, :kill)
      spawn(Server, :start, [port_ut_http, "http server"])
      Process.sleep(:timer.seconds(1))

      {:ok, %{response: response, port: port}} = Worker.get_banner(host_ut, port_ut_http)

      assert port_ut_http == port
      assert response =~ ~r/http/i
    end

    test "get error and reason when port is not open in host" do
      host_ut = "127.0.0.1"
      port_ut = 9999

      {:error, %{response: response, host: host, port: port}} =
        Worker.get_banner(host_ut, port_ut)

      assert host_ut == host
      assert port_ut == port
      assert response =~ ~r/Error returning banner/i
    end

    test "get error and reason when host is not reachable" do
      host_ut = "1.1.1.1"
      port_ut = 9999

      {:error, %{response: response, host: host, port: port}} =
        Worker.get_banner(host_ut, port_ut)

      assert host_ut == host
      assert port_ut == port
      assert response =~ ~r/Error returning banner/i
    end

    test "should get banner with custom payload" do
      host_ut = "127.0.0.1"
      port_ut_http = 8089
      Config.set_write_payload(%{write_payload: "GET / HTTP/1.1\r\nHost: #{host_ut}\r\n\r\n"})

      spawn(Server, :start, [port_ut_http, "hello server"])
      Process.sleep(:timer.seconds(1))

      {:ok, %{response: response, port: port}} = Worker.get_banner(host_ut, port_ut_http)
      assert port_ut_http == port
      assert response =~ ~r/hello server/i
    end

    test "should get banner with nil payload" do
      host_ut = "127.0.0.1"
      port_ut_http = 8088
      Config.set_write_payload(%{write_payload: nil})

      spawn(Server, :start, [port_ut_http, "hello server"])
      Process.sleep(:timer.seconds(1))

      {:ok, %{response: response, port: port}} = Worker.get_banner(host_ut, port_ut_http)
      assert port_ut_http == port
      assert response =~ ~r/hello server/i
    end

    test "should get errors sending payload after socket close" do
      host_ut = "127.0.0.1"
      port_ut_http = 8081
      Config.set_write_payload(%{write_payload: "foobar"})

      spawn(Server, :start, [port_ut_http, "hello server"])
      Process.sleep(:timer.seconds(1))

      {:ok, socket} = Worker.estabilish_connection(host_ut, port_ut_http)
      :gen_tcp.close(socket)
      {status, _reason} = Worker.send_payload(socket, host_ut, port_ut_http)

      assert status == :error
    end
  end
end
