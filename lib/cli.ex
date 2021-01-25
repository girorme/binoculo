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
      switches: [
        help: :boolean,
        ip: :string,
        port: :integer,
        threads: :integer,
        head: :boolean,
        read: :string,
        verbose: :boolean
      ],
      aliases: [
        h: :help,
        p: :port,
        t: :threads,
        r: :read
      ]
    )

    case params do
      [help: true] -> Binoculo.Util.help()
      [] -> Binoculo.Util.help()
      _ -> start_scan(params)
    end
  end

  def start_scan(params) do
    ip = parse_ip_range_type(params)
    port = params[:port]
    threads = params[:threads] || 30
    head = params[:head] || false
    word_to_search = params[:read] || false
    verbose = params[:verbose] || false

    unless ip do
      IO.puts('Invalid ip/range type')
      System.halt(0)
    end

    {start, last} = ip

    Iplist.Ip.range(start, last)
      |> Enum.map(&Iplist.Ip.to_string(&1))
      |> Enum.map(fn (ip) -> %{
          ip: ip,
          port: port,
          head: head
        } end)
      |> Task.async_stream(
        &scan/1,
        max_concurrency: threads,
        timeout: :infinity
        ) |> Enum.filter(fn
        {:ok, {:ok, _, _, raw}} -> if word_to_search, do: String.contains?(raw, word_to_search), else: true
        _ -> if verbose, do: true, else: false
      end)
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
    %{ip: ip, port: port, head: head} = scan_params
    ip = to_charlist(ip)
    sock = :gen_tcp.connect(ip, port, [:binary, active: false])
    case parse_response(sock) do
      {:ok, sock} -> interact(sock, ip: ip, port: port, head: head)
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

  def interact(sock, opts \\ []) do
    if opts[:head] do
      :gen_tcp.send(sock, "HEAD / HTTP/1.1\r\nHost: #{opts[:ip]}\r\n\r\n")
    end

    get_response(sock, ip: opts[:ip], port: opts[:port])
  end

  def get_response(sock, opts) do
    case :gen_tcp.recv(sock, 0) do
      {:ok, data} -> {:ok, opts[:ip], opts[:port], data}
      {:error, :einval} -> {:error, opts[:ip], :einval}
      {:error, :closed} -> {:error, opts[:ip], opts[:port]}
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
