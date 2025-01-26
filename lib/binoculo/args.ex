defmodule Binoculo.Args do
  @moduledoc """
  Parse arguments
  """

  alias Binoculo.Util

  def parse_args(argv) do
    version = Util.version()

    optimus =
      Optimus.new!(
        name: "Binoculo",
        description: "Binoculo: You Know, for Banner Grabbing!",
        version: "Version: #{version}",
        author: "Author: Girorme <g1r0rm3@gmail.com>",
        about: "A banner grabbing tool",
        allow_unknown_args: false,
        parse_double_dash: true,
        flags: [
          verbosity: [
            short: "-v",
            help: "Verbosity level",
            multiple: true
          ]
        ],
        options: [
          host_notation: [
            value_name: "host_notation",
            long: "--range",
            help: "CIDR or IP range: 192.168.1.0/24 or 192.168.1.0..192.168.1.255",
            parser: fn notation ->
              case Util.parse_range_or_cidr_notation(notation) do
                {:error, _} -> {:error, "invalid cidr or notation"}
                {:ok, _} -> {:ok, notation}
              end
            end,
            required: true
          ],
          ports: [
            value_name: "port(s)",
            short: "-p",
            long: "--port",
            help: "Port(s) to scan: 80,443,8080 or 80-8080 or 21,80-8080",
            parser: fn port ->
              case parse_port_arg(port) do
                {:error, _} -> {:error, "invalid port(s)"}
                {:ok, port_parsed} -> {:ok, port_parsed}
              end
            end,
            required: true
          ],
          output: [
            value_name: "output",
            short: "-o",
            long: "--output",
            help: "Output file",
            parser: fn output ->
              # check if output dir exists and create it if not
              File.mkdir_p!("output")

              with {:ok, _file} <- File.open("output/#{output}", [:append]) do
                {:ok, output}
              end
            end
          ],
          write: [
            value_name: "write",
            short: "-w",
            long: "--write",
            help: "Write cutom payload to socket, e.g: GET / HTTP/1.1"
          ],
          read: [
            value_name: "read",
            short: "-r",
            long: "--read",
            help: "Save only responses that match with this string, e.g: Apache | nginx,php",
            parser: fn read_payload ->
              case String.contains?(read_payload, ",") do
                true -> {:ok, String.split(read_payload, ",")}
                false -> {:ok, read_payload}
              end
            end
          ]
        ]
      )

    case String.to_atom(System.get_env("MIX_ENV", "test")) do
      :test ->
        Optimus.parse(optimus, argv)

      _ ->
        {:ok, Optimus.parse!(optimus, argv)}
    end
  end

  defp parse_port_arg(port_arg) do
    ports =
      String.trim(port_arg)
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
