defmodule WorkerTest do
  @moduledoc """
  Main worker (get_banner) tests
  """
  use ExUnit.Case, async: true

  alias Binoculo.{Config, Worker}
  alias Binoculo.Stub.Server

  @ftp_port 21_210
  @http_port 8080
  @custom_http_port 8089
  @custom_http_port_no_crlf 8087
  @nil_payload_port 8088
  @socket_close_port 8081

  setup_all do
    ftp_pid = spawn(Server, :start, [@ftp_port, "ftp server"])
    http_pid = spawn(Server, :start, [@http_port, "http server"])
    custom_http_pid = spawn(Server, :start, [@custom_http_port, "hello server"])
    custom_http_no_crlf_pid = spawn(Server, :start, [@custom_http_port_no_crlf, "hello server"])
    nil_payload_pid = spawn(Server, :start, [@nil_payload_port, "hello server"])
    socket_close_pid = spawn(Server, :start, [@socket_close_port, "hello server"])

    # Wait for the servers to start
    :timer.sleep(100)

    on_exit(fn ->
      [
        ftp_pid,
        http_pid,
        custom_http_pid,
        custom_http_no_crlf_pid,
        nil_payload_pid,
        socket_close_pid
      ]
      |> Enum.each(&Process.exit(&1, :kill))
    end)

    {:ok,
     %{
       ftp_port: @ftp_port,
       http_port: @http_port,
       custom_http_port: @custom_http_port,
       custom_http_no_crlf_port: @custom_http_port_no_crlf,
       nil_payload_port: @nil_payload_port,
       socket_close_port: @socket_close_port
     }}
  end

  describe "Testing the banner grab function" do
    test "get banner passing ip + port", %{ftp_port: ftp_port, http_port: http_port} do
      host_ut = "127.0.0.1"

      {:ok, %{response: response, host: host, port: port}} = Worker.get_banner(host_ut, ftp_port)

      assert host_ut == host
      assert ftp_port == port
      assert response =~ ~r/ftp/i

      {:ok, %{response: response, port: port}} = Worker.get_banner(host_ut, http_port)

      assert http_port == port
      assert response =~ ~r/http/i
    end

    test "get error and reason when port is not open in host" do
      host_ut = "127.0.0.1"
      port_ut = 9999

      {:error, %{response: response, host: host, port: port}} =
        Worker.get_banner(host_ut, port_ut, 1)

      assert host_ut == host
      assert port_ut == port
      assert response =~ ~r/Error returning banner/i
    end

    test "get error and reason when host is not reachable" do
      host_ut = "1.1.1.1"
      port_ut = 9999

      {:error, %{response: response, host: host, port: port}} =
        Worker.get_banner(host_ut, port_ut, 1)

      assert host_ut == host
      assert port_ut == port
      assert response =~ ~r/Error returning banner/i
    end

    test "should get banner with custom payload", %{custom_http_port: custom_http_port} do
      host_ut = "127.0.0.1"
      Config.set_write_payload(%{write_payload: "GET / HTTP/1.1\r\nHost: #{host_ut}\r\n\r\n"})

      {:ok, %{response: response, port: port}} = Worker.get_banner(host_ut, custom_http_port)
      assert custom_http_port == port
      assert response =~ ~r/hello server/i
    end

    test "should get banner with custom payload without \r\n", %{
      custom_http_no_crlf_port: custom_http_no_crlf_port
    } do
      host_ut = "127.0.0.1"
      Config.set_write_payload(%{write_payload: "GET / HTTP/1.1\r\nHost: #{host_ut}"})

      {:ok, %{response: response, port: port}} =
        Worker.get_banner(host_ut, custom_http_no_crlf_port)

      assert custom_http_no_crlf_port == port
      assert response =~ ~r/hello server/i
    end

    test "should get banner with nil payload", %{nil_payload_port: nil_payload_port} do
      host_ut = "127.0.0.1"
      Config.set_write_payload(%{write_payload: nil})

      {:ok, %{response: response, port: port}} = Worker.get_banner(host_ut, nil_payload_port)
      assert nil_payload_port == port
      assert response =~ ~r/hello server/i
    end

    test "should get errors sending payload after socket close", %{
      socket_close_port: socket_close_port
    } do
      host_ut = "127.0.0.1"
      Config.set_write_payload(%{write_payload: "foobar"})

      {:ok, socket} = Worker.estabilish_connection(host_ut, socket_close_port, 1)
      :gen_tcp.close(socket)
      {status, _reason} = Worker.send_payload(socket, host_ut, socket_close_port)

      assert status == :error
    end
  end
end
