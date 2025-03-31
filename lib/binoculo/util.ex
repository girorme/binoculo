defmodule Binoculo.Util do
  @moduledoc """
  Util functions
  """

  @ip_common_re ~r/^(\d{1,3}\.){3}\d{1,3}$/
  @ip_cidr_re ~r/^([0-9]{1,3}\.){3}[0-9]{1,3}(\/([0-9]|[1-2][0-9]|3[0-2]))?$/
  @ip_range_re ~r/^(([0-9]{1,3}\.){3}[0-9]{1,3})\.\.(?1)$/

  alias IP

  def version() do
    :application.get_key(:binoculo, :vsn)
    |> elem(1)
    |> List.to_string()
  end

  def banner() do
    """

    ######   ####   ##   ##   #####    ######  ##   ##  ####      #####
    #######  ####   ###  ##  #######  #######  ##   ##  ####     #######
     ## ###   ##    #### ##  ##   ##  ###  ##  ##   ##   ##      ##   ##
     #####    ##    #######  ##   ##  ##       ##   ##   ##      ##   ##
     #####    ##    #######  ##   ##  ##       ##   ##   ##      ##   ##
     ## ###   ##    ## ####  ##   ##  ###  ##  ##   ##   ##  ##  ##   ##
    #######  ####   ##  ###  #######  #######  #######  #######  #######
    ######   ####   ##   ##   #####    ######   #####   #######   #####
    #{version()}

    By Girorme # P0cl4bs
    """
  end

  def parse_range_or_cidr_notation(notation) do
    cond do
      Regex.match?(@ip_common_re, notation) ->
        IP.Subnet.from_string(notation <> "/32")

      Regex.match?(@ip_cidr_re, notation) ->
        IP.Subnet.from_string(notation)

      Regex.match?(@ip_range_re, notation) ->
        IP.Range.from_string(notation)

      true ->
        {:error, "invalid_format"}
    end
  end

  def format_http_response(http_response) do
    header_and_body = parse_header_and_body(http_response)

    [http_code | key_value] = String.split(header_and_body[:header], "\r\n")

    resp =
      unless empty?(key_value) do
        for session <- key_value, into: %{} do
          [key, value] = String.split(session, ": ", parts: 2)
          {key, value}
        end
      end

    Map.put(
      resp || %{},
      "Code",
      http_code
    )
  end

  def get_possible_http_ports(), do: [8080, 80, 443]

  def host_info_to_text_template(%{host: host, port: port, response: response} = _host_info) do
    """
    --=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--
    Host: #{host}
    Port: #{port}

    #{response}
    --=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--
    """
  end

  def parse_header_and_body(http_response) do
    case String.split(http_response, "\r\n\r\n") do
      [header, body] -> %{header: header, body: body}
      header -> %{header: Enum.at(header, 0), body: nil}
    end
  end

  def empty?(val) when val == [], do: true
  def empty?(_val), do: false

  def parse_ports_notation(ports_notation) do
    ports =
      String.trim(ports_notation)
      |> String.split(",")
      |> Enum.map(fn port ->
        case Regex.match?(~r/^\d+(-\d+)?$/, port) do
          false -> {:error, port}
          _ -> {:ok, port}
        end
      end)
      |> Enum.split_with(fn {status, _port_value} -> status == :error end)

    {invalid_ports, ports} = ports

    if Enum.count(invalid_ports) > 0 do
      {:error, "invalid port(s): #{inspect(invalid_ports)}"}
    else
      Enum.map(ports, fn {:ok, port} -> port end)
      |> generate_port_range()
    end
  end

  def generate_port_range(ports) do
    ports
    |> Enum.reduce_while({:ok, []}, fn port, {:ok, acc} ->
      case parse_port(port) do
        {:ok, port_list} -> {:cont, {:ok, acc ++ port_list}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp parse_port(port) do
    case String.split(port, "-") do
      [single_port] ->
        {:ok, [String.to_integer(single_port)]}

      [start_port, end_port] ->
        start_port = String.to_integer(start_port)
        end_port = String.to_integer(end_port)

        if start_port <= end_port do
          {:ok, Enum.to_list(start_port..end_port)}
        else
          {:error, "Invalid range: start port must be less than or equal to end port"}
        end
    end
  end
end
