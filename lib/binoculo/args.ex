defmodule Binoculo.Args do
  @moduledoc """
  Parse arguments
  """

  alias Binoculo.Util

  def parse_args(argv) do
    version = Util.version()
    no_args = Enum.empty?(argv)
    is_api = Enum.any?(argv, fn arg -> arg in ["--server", "-s"] end)

    host_notation_config = [
      value_name: "host_notation",
      long: "--range",
      help: "CIDR or IP range: 192.168.1.0/24 or 192.168.1.0..192.168.1.255",
      parser: fn notation ->
        case Util.parse_range_or_cidr_notation(notation) do
          {:error, _} -> {:error, "invalid cidr or notation"}
          {:ok, _} -> {:ok, notation}
        end
      end,
      required:
        if no_args or is_api do
          false
        else
          true
        end
    ]

    port_config = [
      value_name: "port(s)",
      short: "-p",
      long: "--port",
      help: "Port(s) to scan: 80,443,8080 or 80-8080 or 21,80-8080",
      parser: fn port ->
        case Util.parse_ports_notation(port) do
          {:error, _} -> {:error, "invalid port(s)"}
          {:ok, port_parsed} -> {:ok, port_parsed}
        end
      end,
      required:
        if no_args or is_api do
          false
        else
          true
        end
    ]

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
          ],
          server: [
            value_name: "server",
            short: "-s",
            long: "--server",
            help: "Start API server"
          ]
        ],
        options: [
          host_notation: host_notation_config,
          ports: port_config,
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
            end,
            default: "output.txt"
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
end
