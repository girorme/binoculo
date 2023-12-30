defmodule Binoculo do
  @moduledoc """
  Documentation for `Binoculo`.
  """

  alias Binoculo.{Config, CrossSaver, Results, Util, Maestro, Args}

  def main(argv) do
    parsed_args = Args.parse_args(argv)
    host_notation = get_in(parsed_args, [Access.key!(:options), Access.key!(:host_notation)])
    ports = get_in(parsed_args, [Access.key!(:options), Access.key!(:ports)])
    output = get_in(parsed_args, [Access.key!(:options), Access.key!(:output)])
    port_count = Enum.count(ports)

    Config.set_output_file(output)

    {:ok, qty_to_run} = Maestro.start_get_banner_workers(host_notation, ports)

    IO.puts(Util.banner())
    IO.puts("Binoculo started!")
    IO.puts("[*] Host: #{host_notation}")
    IO.puts("[*] Ports: #{port_count}: #{Enum.join(Enum.take(ports, 5), ", ")}...")
    IO.puts("[*] Total hosts to scan: #{qty_to_run}, with #{port_count} ports each")
    IO.puts("Waiting initialisation of workers and so on...")

    Process.sleep(:timer.seconds(2))

    IO.puts("Working...")

    ProgressBar.render_spinner([text: "Loading", done: "Finished"], fn ->
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
end
