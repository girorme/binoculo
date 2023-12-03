defmodule BinoculoDaemon do
  @moduledoc """
  Documentation for `BinoculoDaemon`.
  """

  alias BinoculoDaemon.Results
  alias BinoculoDaemon.Maestro
  alias BinoculoDaemon.Args
  alias BinoculoDaemon.Util

  def main(argv) do
    parsed_args = Args.parse_args(argv)
    host_notation = get_in(parsed_args, [Access.key!(:options), Access.key!(:host_notation)])
    ports = get_in(parsed_args, [Access.key!(:options), Access.key!(:ports)])

    {:ok, qty_to_run} = Maestro.start_get_banner_workers(host_notation, ports)
    port_count = Enum.count(ports)

    IO.puts(Util.banner())

    IO.puts("BinoculoDaemon started!")
    IO.puts("[*] Host: #{host_notation}")
    IO.puts("[*] Ports: #{port_count}: #{Enum.join(Enum.take(ports, 5), ", ")}...")
    IO.puts("[*] Total hosts to scan: #{qty_to_run}, with #{port_count} ports each")

    Process.sleep(:timer.seconds(2))

    ProgressBar.render_spinner([text: "Loading", done: "Finished"], fn ->
      progress()
    end)
  end

  def progress() do
    IO.write("\rScanning: #{Results.get_qty_running()} host(s):port(s) combination")

    case Results.get_qty_running() do
      0 -> :finished
      _ -> progress()
    end
  end
end
