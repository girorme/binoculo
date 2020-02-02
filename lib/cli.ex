defmodule Binoculo.CLI do
  def main(args) do
    IO.puts("Binoculo cli\n\n")
    args |> parse_args
  end

  def parse_args(args) do
    {params, _, _} = OptionParser.parse(
      args,
      switches: [help: :boolean, ip: :string, port: :integer],
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
    |> Task.async_stream(&scan/1, max_concurrency: 30, on_timeout: :kill_task)
    |> Enum.map(&finish/1)
  end

  def finish({:ok, raw}) do
    {_, host, response} = raw
    IO.puts("[] #{host}\n--\n#{response}")
  end

  def finish({:error, raw}) do
    {_, host, response} = raw
    IO.puts("[] #{host}\n--\n#{response}")
  end

  def finish({:exit, :timeout}) do

  end
  def scan(ip_and_port) do
    {host, port} = ip_and_port
    host = to_charlist(host)
    sock = :gen_tcp.connect(host, port, [:binary, active: false])
    case parse_response(sock) do
      {:ok, sock} -> connect_and_response(sock, host, port)
      {:error, reason} -> {:error, host, reason}
    end
  end

  def parse_response({:ok, sock}) do
    {:ok, sock}
  end

  def parse_response({:error, reason}) do
    {:error, "Error: #{reason}"}
  end

  def connect_and_response(sock, host, port) do
    if port == 80 or port == 443 do
      :gen_tcp.send(sock, "HEAD / HTTP/1.1\r\nHost: #{host}\r\n\r\n")
    end

    get_response(sock, host)
  end

  def get_response(sock, host) do
    case :gen_tcp.recv(sock, 0) do
      {:ok, data} -> {:ok, host, data}
      {:error, :einval} -> {:error, host, :einval}
    end
  end
end
