defmodule ConfigTest do
  use ExUnit.Case, async: true

  alias Binoculo.Config

  setup_all do
    config = %{
      output_file: "result.txt",
      write_payload: "GET / HTTP/1.1\r\n\r\n",
      read_payload: "HTTP/1.1 200 OK\r\n\r\n"
    }

    {:ok, config: config}
  end

  test "should set output file", %{config: config} do
    assert config == Config.set_output_file(config)
    assert config.output_file == Config.get_output_file()
  end

  test "should set write payload", %{config: config} do
    assert config == Config.set_write_payload(config)
    assert config.write_payload == Config.get_write_payload()
  end

  test "should set read payload", %{config: config} do
    assert config == Config.set_read_payload(config)
    assert config.read_payload == Config.get_read_payload()
  end

  test "should start maestro via config module" do
    assert {:ok, pid} = Config.start_maestro()
    assert is_pid(pid)
    Process.exit(pid, :kill)
  end
end
