defmodule Binoculo.CLI do
  def main(args) do
    IO.puts("Binoculo cli")
    args |> parse_args
  end

  def parse_args(args) do
    {params, _, _} = OptionParser.parse(
      args,
      switches: [help: :boolean, ip: :string, port: :string],
      aliases: [h: :help, p: :port]
    )

    case params do
      [help: true] -> Binoculo.Util.help()
      [ip: ip_value, port: port_value] -> start_scan(ip_value, port_value)
      _ -> Binoculo.Util.help()
    end
  end

  def start_scan(ip, port) do
    Iplist.Ip.range(ip)
    |> Enum.map(&Iplist.Ip.to_string(&1))
    |> Enum.map(fn (ip) -> {ip, port} end)
    |> Task.async_stream(&scan/1, max_concurrency: 5, on_timeout: :kill_task)
    |> Enum.map(fn ({:ok, value}) -> value end)
    |> IO.inspect
  end

  def scan(ip_and_port) do
    {host, port} = ip_and_port
    {host, port}
  end
end
