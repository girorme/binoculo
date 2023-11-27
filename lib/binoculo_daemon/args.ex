defmodule BinoculoDaemon.Args do
  alias BinoculoDaemon.Util

  def parse_args(argv) do
    version =
      :application.get_key(:binoculo_daemon, :vsn)
      |> elem(1)
      |> List.to_string()

    Optimus.new!(
      name: "Binoculo",
      description: "Binoculo: You Know, for Banner Grabbing!",
      version: "Version: #{version}",
      author: "Author: Girorme <g1r0rm3@gmail.com>",
      about: "A banner grabbing tool",
      allow_unknown_args: false,
      parse_double_dash: true,
      flags: [
        print_header: [
          long: "--dashboard",
          help: "Launches a shodan like dashboard",
          multiple: false,
        ],
        verbosity: [
          short: "-v",
          help: "Verbosity level",
          multiple: true,
        ],
      ],
      options: [
        host_notation: [
          value_name: "host_notation",
          short: "-r",
          long: "--range",
          help: "CIDR or IP range: 192.168.1.0/24 or 192.168.1.0..192.168.1.255",
          parser: fn(notation) ->
            case Util.parse_range_or_cidr_notation(notation) do
              {:error, _} -> {:error, "invalid cidr or notation"}
              {:ok, _} -> {:ok, notation}
            end
          end,
          required: true
        ],
        port: [
          value_name: "port",
          short: "-p",
          long: "--port",
          help: "Port(s) to scan",
          parser: fn(port) ->
            case Integer.parse(port) do
              :error -> {:error, "invalid port"}
              {port_parsed, _} -> {:ok, port_parsed}
            end
          end,
        ]
      ]
    ) |> Optimus.parse!(argv)
  end
end
