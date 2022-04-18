defmodule Binoculo.CLI do
  @ip_cidr_re ~r/^([0-9]{1,3}\.){3}[0-9]{1,3}(\/([0-9]|[1-2][0-9]|3[0-2]))?$/
  @ip_range_re ~r/^(([0-9]{1,3}\.){3}[0-9]{1,3})\.\.(?1)$/

  def main(args) do
    IO.puts("Binoculo cli\n")
    args |> parse_args
  end

  def parse_args(args) do
    {params, _, _} =
      OptionParser.parse(
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
    |> Enum.map(&Iplist.Ip.to_string/1)
    |> Enum.map(fn ip ->
      %{
        ip: ip,
        port: port,
        head: head
      }
    end)
    |> Task.async_stream(
      &scan/1,
      max_concurrency: threads,
      timeout: :infinity
    )
    |> Enum.filter(fn
      {:ok, {:ok, _, _, raw}} ->
        if word_to_search, do: String.contains?(raw, word_to_search), else: true

      _ ->
        if verbose, do: true, else: false
    end)
    |> Enum.map(&finish/1)
  end

  defp finish({:ok, raw}) do
    case raw do
      {_, host, port, response} -> IO.puts("[] #{host}:#{port}\n--\n#{response}")
      {_, host, port} -> IO.puts("[] #{host}:#{port}\n--\n")
    end
  end

  defp finish({:error, raw}) do
    {_, host, port, response} = raw
    IO.puts("[] #{host}:#{port}\n--\n#{response}\n")
  end

  defp finish({:exit, :timeout}) do
  end

  defp scan(%{ip: ip, port: port, head: head}) do
    IO.puts("[] Scanning ip: #{ip} - port: #{port}]")

    ip = to_charlist(ip)
    sock = :gen_tcp.connect(ip, port, [active: false], :timer.seconds(5))

    case parse_response(sock) do
      {:ok, sock} -> interact(sock, ip: ip, port: port, head: head)
      {:error, reason} -> {:error, ip, reason}
    end
  end

  defp parse_response({:ok, sock}) do
    {:ok, sock}
  end

  defp parse_response({:error, reason}) do
    {:error, "Error: #{reason}"}
  end

  defp interact(sock, opts) do

    payload = case opts[:head] do
      true -> http_head_payload(opts[:ip])
      _ -> "binoculo\r\n"
    end

    :gen_tcp.send(sock, payload)
    get_response(sock, ip: opts[:ip], port: opts[:port])
  end

  defp get_response(sock, opts) do
    #response = :gen_tcp.recv(sock, 0)

    case :gen_tcp.recv(sock, 0) do
     {:ok, data} -> {:ok, opts[:ip], opts[:port], data}
     {:error, :einval} -> {:error, opts[:ip], opts[:port], :einval}
     {:error, :closed} -> {:error, opts[:ip], opts[:port], :closed}
    end
  end

  defp parse_ip_range_type(params) do
    ip = params[:ip]

    cond do
      String.match?(ip, @ip_cidr_re) ->
        ip |> CIDR.parse() |> start_last_from_cidr

      String.match?(ip, @ip_range_re) ->
        ip
        |> String.split("..")
        |> List.to_tuple()

      true ->
        false
    end
  end

  defp start_last_from_cidr(%CIDR{first: first, hosts: _, last: last, mask: _}) do
    {first, last}
  end

  defp http_head_payload(ip), do: "HEAD / HTTP/1.1\r\nHost: #{ip}\r\n\r\n"
end
