defmodule ConfigTest do
  use ExUnit.Case, async: true

  alias Binoculo.Config

  test "should set output file" do
    assert :ok == Config.set_output_file("test.txt")
    assert "output/test.txt" == Config.get_output_file()
  end

  test "should set write payload" do
    assert :ok == Config.set_write_payload("GET / HTTP/1.1\r\n\r\n")
    assert "GET / HTTP/1.1\r\n\r\n" == Config.get_write_payload()
  end

  test "should set read payload" do
    assert :ok == Config.set_read_payload("HTTP/1.1 200 OK\r\n\r\n")
    assert "HTTP/1.1 200 OK\r\n\r\n" == Config.get_read_payload()
  end

  test "should start maestro via config module" do
    assert {:ok, pid} = Config.start_maestro()
    assert is_pid(pid)
  end
end
