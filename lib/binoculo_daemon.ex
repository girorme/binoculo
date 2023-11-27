defmodule BinoculoDaemon do
  @moduledoc """
  Documentation for `BinoculoDaemon`.
  """

  alias BinoculoDaemon.Results
  alias BinoculoDaemon.Maestro
  alias BinoculoDaemon.Args

  def main(argv) do
    parsed_args = Args.parse_args(argv)
    host_notation = get_in(parsed_args, [Access.key!(:options), Access.key!(:host_notation)])
    port = get_in(parsed_args, [Access.key!(:options), Access.key!(:port)])

    {:ok, qty_to_run} = Maestro.start_get_banner_workers(host_notation, port)

    IO.puts("BinoculoDaemon started!")
    IO.puts("[*] Host: #{host_notation}")
    IO.puts("[*] Port: #{port}")
    IO.puts("[*] Total to run: #{qty_to_run}")

    ProgressBar.render_spinner [text: "Loading", done: "Finished"], fn ->
      progress()
    end
  end

  def progress() do
    IO.write("\rScanning: #{Results.get_qty_running()} hosts")

    case Results.get_qty_running() do
      0 -> :finished
      _ -> progress()
    end
  end
end
