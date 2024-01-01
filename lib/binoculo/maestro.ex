defmodule Binoculo.Maestro do
  @moduledoc """
  Coordinate workers spawn and result saving"
  """
  use GenServer

  require Logger
  alias Binoculo.{Results, Worker, Util}

  def start_get_banner_workers(host_notation, ports) do
    {:ok, range} = Util.parse_range_or_cidr_notation(host_notation)

    # improve logic to receive "daemon" mode, to run in background receiving commands
    range
    |> Stream.map(&IP.to_string/1)
    |> Task.async_stream(
      fn host ->
        Enum.each(ports, fn port ->
          start_worker(host, port)
        end)
      end,
      max_concurrency: 200,
      timeout: :infinity,
      ordered: false
    )
    |> Stream.run()

    qty_to_run = Enum.to_list(range) |> Enum.count()

    {:ok, qty_to_run}
  end

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @spec init(any()) :: {:ok, any()}
  def init(state) do
    start_result_db()
    {:ok, state}
  end

  defp start_worker(host, port) do
    GenServer.cast(__MODULE__, {:start_worker, %{host: host, port: port}})
  end

  defp start_result_db() do
    with false <- Results.is_started?() do
      Results.init_db()
    end
  end

  defp finish_item(host_info) do
    Results.finish_item(host_info)
    :ok
  end

  defp remove_item(host_info) do
    Results.remove_item(host_info)
    :ok
  end

  def handle_cast({:start_worker, %{host: host, port: port} = host_info}, state) do
    Results.add_item(host_info)
    Task.async(Worker, :get_banner, [host, port])
    {:noreply, state}
  end

  def handle_info({_ref, {status, host_info}}, state) do
    host_info =
      Map.put(
        host_info,
        :id,
        :crypto.hash(:md5, "#{host_info.host} <> #{host_info.port}") |> Base.encode16()
      )

    case status do
      :ok -> finish_item(host_info)
      :error -> remove_item(host_info)
    end

    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
