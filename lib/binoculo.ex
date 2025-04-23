defmodule Binoculo do
  @moduledoc """
  Documentation for `Binoculo`.
  """

  alias Binoculo.{Config, CrossSaver, Results, Util, Maestro, Args}
  alias Binoculo.Api.Server

  def main(argv) do
    {:ok, parsed_args} = Args.parse_args(argv)

    server_mode =
      get_in(parsed_args, [Access.key!(:flags), Access.key!(:server)])

    case server_mode do
      true -> start_server()
      _ -> init_cli(parsed_args)
    end
  end

  defp start_server do
    IO.puts("Starting API server on port 4000")
    # start the server
    Server.start(:normal, [])
    :timer.sleep(:infinity)
  end

  def init_cli(parsed_args) do
    host_notation = get_in(parsed_args, [Access.key!(:options), Access.key!(:host_notation)])
    ports = get_in(parsed_args, [Access.key!(:options), Access.key!(:ports)])
    output = get_in(parsed_args, [Access.key!(:options), Access.key!(:output)])
    port_count = Enum.count(ports)
    write_payload = get_in(parsed_args, [Access.key!(:options), Access.key!(:write)])
    read_payload = get_in(parsed_args, [Access.key!(:options), Access.key!(:read)])

    config = %{
      output_file: output,
      write_payload: write_payload,
      read_payload: read_payload
    }

    config
    |> Config.set_output_file()
    |> Config.set_write_payload()
    |> Config.set_read_payload()

    Config.start_maestro()

    {:ok, qty_to_run} = Maestro.start_get_banner_workers(host_notation, ports)

    IO.puts(Util.banner())
    IO.puts("Binoculo started!")
    IO.puts("[*] Host: #{host_notation}")
    IO.puts("[*] Ports: #{port_count}: #{Enum.join(Enum.take(ports, 5), ", ")}...")
    IO.puts("[*] Total hosts to scan: #{qty_to_run}, with #{port_count} ports each")
    IO.puts("Waiting initialisation of workers and so on...")

    wait_for_workers()

    IO.puts("Working...")

    ProgressBar.render_spinner([frames: :bars], fn ->
      progress()
    end)

    IO.puts("\n\nSaving results...")

    CrossSaver.save_results()
  end

  def progress() do
    IO.write("\rScanning: #{Results.get_qty_running()} host(s):port(s) combination")

    case Results.get_qty_running() do
      0 -> :finished
      _ -> progress()
    end
  end

  defp wait_for_workers() do
    if Results.get_qty_running() == 0 do
      Process.sleep(:timer.seconds(1))
      wait_for_workers()
    end
  end
end
