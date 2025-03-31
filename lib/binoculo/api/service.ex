defmodule Binoculo.Api.Service do
  @moduledoc """
  Service to handle API requests
  """

  alias Binoculo.{Util, Worker}

  def get_banners(host_notation, ports) do
    {:ok, range} = Util.parse_range_or_cidr_notation(host_notation)
    {:ok, ports} = Util.parse_ports_notation(ports)

    range
    |> Stream.map(&IP.to_string/1)
    |> Task.async_stream(
      fn host ->
        Enum.map(ports, fn port ->
          Worker.get_banner(host, port)
        end)
      end,
      max_concurrency: 200,
      timeout: :infinity,
      ordered: false
    )
    # flatten the stream
    |> Stream.flat_map(fn
      {:ok, result} -> result
      {:error, _} -> []
    end)
    |> Stream.filter(fn
      {:ok, _} -> true
      {:error, _} -> false
    end)
    |> Stream.map(fn {:ok, result} -> result end)
    |> Enum.to_list()
  end
end
