defmodule Binoculo.CLI do
  @ip_cidr_re ~r/^([0-9]{1,3}\.){3}[0-9]{1,3}(\/([0-9]|[1-2][0-9]|3[0-2]))?$/
  @ip_range_re ~r/^([0-9]{1,3}\.){3}[0-9]{1,3}(\/([0-9]|[1-2][0-9]|3[0-2]))?\.\.([0-9]{1,3}\.){3}[0-9]{1,3}(\/([0-9]|[1-2][0-9]|3[0-2]))?$/

  def main(args) do
    IO.puts("Binoculo cli\n")
    args |> parse_args
  end

  def parse_args(args) do
    {params, _, _} = OptionParser.parse(
      args,
      switches: [help: :boolean, ip: :string, port: :integer, threads: :integer],
      aliases: [h: :help, p: :port, t: :threads]
    )

    case params do
      [help: true] -> Binoculo.Util.help()
      [
        ip: ip_value,
        port: port_value,
        threads: threads_value
      ] -> start_scan(ip_value, port_value, threads_value)
      [
        ip: ip_value,
        port: port_value
      ] -> start_scan(ip_value, port_value, 30)
      _ -> Binoculo.Util.help()
    end
  end

  def start_scan(ip, port, threads_value) do
    if String.match?(ip, @ip_range_re) do
      Iplist.Ip.range(ip)
      |> Enum.map(&Iplist.Ip.to_string(&1))
      |> Enum.map(fn (ip) -> {ip, port} end)
      |> Task.async_stream(&scan/1, max_concurrency: threads_value, on_timeout: :kill_task)
      |> Enum.map(&finish/1)

      System.halt(0)
    end

    IO.puts('Invalid ip/range format')
  end

  def finish({:ok, raw}) do
    case raw do
      {_, host, port, response} -> IO.puts("[] #{host}:#{port}\n--\n#{response}")
      {_, host, port} -> IO.puts("[] #{host}:#{port}\n--\n")
    end
  end

  def finish({:error, raw}) do
    {_, host, port, response} = raw
    IO.puts("[] #{host}:#{port}\n--\n#{response}\n")
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

  def parse_response({:error, host, reason}) do
    {:error, "Error: #{host}: #{reason}"}
  end

  def connect_and_response(sock, host, port) do
    if port == 80 or port == 443 do
      :gen_tcp.send(sock, "HEAD / HTTP/1.1\r\nHost: #{host}\r\n\r\n")
    end

    get_response(sock, host, port)
  end

  def get_response(sock, host, port) do
    case :gen_tcp.recv(sock, 0) do
      {:ok, data} -> {:ok, host, port, data}
      {:error, :einval} -> {:error, host, :einval}
      {:error, :closed} -> {:error, host, port}
    end
  end
end
