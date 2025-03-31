defmodule Binoculo.Api.Service do
  @moduledoc """
  Service to handle API requests
  """

  alias Binoculo.{Util, Worker}

  def get_banners(host_notation, ports, read, page \\ 1, page_size \\ 10) do
    {:ok, range} = Util.parse_range_or_cidr_notation(host_notation)
    {:ok, ports} = Util.parse_ports_notation(ports)
    read_payload = parse_read_payload(read)

    results =
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
        {:ok, result} ->
          if is_nil(read_payload) do
            true
          else
            String.contains?(result.response, read_payload)
          end

        {:error, _} ->
          false
      end)
      |> Stream.map(fn {:ok, result} -> result end)
      |> Enum.to_list()

    # Apply pagination
    paginated_results = paginate(results, page, page_size)

    %{
      total: length(results),
      page: page,
      page_size: page_size,
      results: paginated_results
    }
  end

  defp paginate(results, page, page_size) do
    results
    |> Enum.chunk_every(page_size)
    |> Enum.at(page - 1, [])
  end

  def parse_read_payload(nil), do: nil

  def parse_read_payload(read) do
    case String.contains?(read, ",") do
      true -> String.split(read, ",")
      false -> read
    end
  end
end
