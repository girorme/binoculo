defmodule Binoculo.Args do
  @moduledoc """
  Parse arguments
  """

  alias Binoculo.Util

  def parse_args(argv) do
    version = Util.version()

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
              :error -> {:error, "invalid port(s)"}
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
            case File.open("output/#{output}", [:append]) do
              {:ok, _file} ->
                {:ok, output}

              {:error, _} ->
                if Mix.env() == :test do
                  {:ok, output}
                else
                  {:error, "invalid output file"}
                end
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
          help: "Save only responses that match with this string, e.g: Apache"
        ]
      ]
    )
    |> Optimus.parse!(argv)
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
      :error
    else
      {:ok, parse_valid_ports(ports)}
    end
  end

  defp parse_valid_ports(ports) do
    Enum.map(ports, fn {_, port} ->
      case String.split(port, "-") do
        [port] ->
          String.to_integer(port)

        [port_start, port_end] ->
          range_from_port(port_start, port_end)
      end
    end)
    |> List.flatten()
    |> Enum.sort()
  end

  defp range_from_port(port_start, port_end) do
    port_start = String.to_integer(port_start)
    port_end = String.to_integer(port_end)

    if port_start > port_end do
      IO.puts("Invalid port range: #{port_start} > #{port_end}")
      System.halt(0)
    end

    Enum.to_list(port_start..port_end)
  end
end
