defmodule BinoculoDaemon.Maestro do
  @moduledoc """
  Coordinate workers spawn and result saving"
  """
  use GenServer

  require Logger
  alias BinoculoDaemon.Msearch
  alias BinoculoDaemon.{Results, Worker, Util}

  def start_get_banner_workers(host_notation, port) do
    {:ok, range} = Util.parse_range_or_cidr_notation(host_notation)

    range
    |> Stream.map(&IP.to_string/1)
    |> Task.async_stream(&GenServer.cast(__MODULE__, {:start_worker, %{host: &1, port: port}}),
      max_concurrency: 200,
      timeout: :infinity,
      ordered: false
    )
    |> Stream.run()
  end

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_result_db() do
    with false <- Results.is_started?() do
      Logger.info("Starting results db...")
      Results.init_db()
    end
  end

  @spec init(any()) :: {:ok, any()}
  def init(state) do
    Logger.info("Starting Maestro...")
    start_result_db()
    {:ok, state}
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

  def finish_item(host_info) do
    Results.finish_item(host_info)

    case Msearch.save(host_info) do
      {:ok, _response} -> :ok
      {:error, response} -> Logger.info("[#{host_info.host}:#{host_info.port}] Error saving result to msearch: #{response}")
      {:error, _, response} -> Logger.info("[#{host_info.host}:#{host_info.port}] Error saving result to msearch: #{response}")
    end

    :ok
  end

  def remove_item(host_info) do
    Results.remove_item(host_info)
    :ok
  end
end
