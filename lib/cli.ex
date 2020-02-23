defmodule Binoculo.CLI do
  @ip_cidr_re ~r/^([0-9]{1,3}\.){3}[0-9]{1,3}(\/([0-9]|[1-2][0-9]|3[0-2]))?$/
  @ip_range_re ~r/^(([0-9]{1,3}\.){3}[0-9]{1,3})\.\.(?1)$/

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
      _ -> start_scan(params)
    end
  end

  def start_scan(params) do
    ip = parse_ip_range_type(params)
    port = params[:port]
    threads = params[:threads] || 30
    head = params[:head] || false

    if ip == false do
      IO.puts('Invalid ip/range type')
      System.halt(0)
    end

    {start, last} = ip

    Iplist.Ip.range(start, last)
      |> Enum.map(&Iplist.Ip.to_string(&1))
      |> Enum.map(fn (ip) -> %{
          host: {ip, port},
          head: head
        } end)
      |> Task.async_stream(&scan/1, max_concurrency: threads, on_timeout: :kill_task)
      |> Enum.map(&finish/1)
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

  def scan(scan_params) do
    %{host: host, head: head} = scan_params
    {ip, port} = host
    ip = to_charlist(ip)
    sock = :gen_tcp.connect(ip, port, [:binary, active: false])
    case parse_response(sock) do
      {:ok, sock} -> connect_and_response(sock, ip, port, head)
      {:error, reason} -> {:error, ip, reason}
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

  def connect_and_response(sock, host, port, head) do
    if head or port == 80 or port == 443 do
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

  def parse_ip_range_type(params) do
    ip = params[:ip]
    cond do
      String.match?(ip, @ip_cidr_re) ->
        ip |> CIDR.parse() |> start_last_from_cidr
      String.match?(ip, @ip_range_re) ->
        ip
          |> String.split("..")
          |> List.to_tuple
      true ->
        false
    end
  end

  def start_last_from_cidr(%CIDR{first: first, hosts: _, last: last, mask: _}) do
    {first, last}
  end
end
