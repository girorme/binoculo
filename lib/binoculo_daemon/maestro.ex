defmodule BinoculoDaemon.Maestro do
  @moduledoc """
  Coordinate workers spawn and result saving"
  """
  use GenServer

  require Logger
  alias BinoculoDaemon.{Worker, Util}

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

  @spec init(any()) :: {:ok, any()}
  def init(state) do
    Logger.info("Starting Maestro...")
    {:ok, state}
  end

  def handle_cast({:start_worker, %{host: host, port: port}}, state) do
    Task.async(Worker, :get_banner, [host, port])
    {:noreply, state}
  end

  def handle_info({_ref, {:ok, msg}}, state) do
    Logger.info(inspect(msg))
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
