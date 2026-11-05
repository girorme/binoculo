defmodule Binoculo.Results do
  @moduledoc """
  Store scan results and progress counters.

  Each banner is a single ETS row (O(1) insert) and the progress is kept in
  `:counters`, so reading the progress never copies the results.

  Errors are always counted per `{stage, reason}` (cheap); the failed `host:port` rows
  are only kept when `init_db/2` is called with `keep_errors: true`.

  The ETS tables are owned by the process that calls `init_db/2`.
  """

  @table_name :binoculo_results
  @stats_table :binoculo_error_stats
  @errors_table :binoculo_error_rows
  @keep_errors_key {__MODULE__, :keep_errors}
  @counters_key {__MODULE__, :counters}

  # counters layout: 1 = ok, 2 = error, 3 = resource_error, 4.. = done per partition
  @slots %{ok: 1, error: 2, resource_error: 3}
  @partition_offset 3

  @doc """
  (Re)creates the results table and zeroed counters for `partitions` partitions.
  """
  @spec init_db(pos_integer(), keyword()) :: :ok
  def init_db(partitions \\ 1, opts \\ []) do
    delete_db()

    for table <- [@table_name, @stats_table, @errors_table] do
      :ets.new(table, [:set, :public, :named_table, write_concurrency: true])
    end

    :persistent_term.put(@counters_key, :counters.new(@partition_offset + partitions, []))
    :persistent_term.put(@keep_errors_key, Keyword.get(opts, :keep_errors, false))
    :ok
  end

  def delete_db() do
    # one by one: tables of a dead owner are removed individually by the VM
    for table <- [@table_name, @stats_table, @errors_table], :ets.info(table) != :undefined do
      :ets.delete(table)
    end

    :persistent_term.erase(@counters_key)
    :persistent_term.erase(@keep_errors_key)
    :ok
  end

  def is_started?() do
    case :ets.info(@table_name) do
      :undefined -> false
      _ -> true
    end
  end

  @doc """
  Stores a banner result. The `id` (md5 of host and port) is the Meilisearch primary key.
  """
  @spec put_result(map()) :: :ok
  def put_result(%{host: host, port: port} = info) do
    id = :crypto.hash(:md5, "#{host} <> #{port}") |> Base.encode16()
    :ets.insert(@table_name, {id, Map.put(info, :id, id)})
    :ok
  end

  @doc """
  Records why a unit failed: counts it by `{stage, reason}` and, when enabled,
  keeps the `host:port` for the errors file.
  """
  @spec put_error(map()) :: :ok
  def put_error(%{reason: reason} = info) do
    stage = Map.get(info, :stage, :unknown)
    :ets.update_counter(@stats_table, {stage, reason}, 1, {{stage, reason}, 0})

    if info[:host] && :persistent_term.get(@keep_errors_key, false) do
      :ets.insert(@errors_table, {{info[:host], info[:port]}, stage, reason})
    end

    :ok
  end

  @doc "Error counts as `{stage, reason, count}`, most frequent first."
  @spec error_breakdown() :: [{atom(), term(), non_neg_integer()}]
  def error_breakdown() do
    @stats_table
    |> :ets.tab2list()
    |> Enum.map(fn {{stage, reason}, count} -> {stage, reason, count} end)
    |> Enum.sort_by(fn {_, _, count} -> -count end)
  end

  @doc "Kept failed units as `{host, port, stage, reason}` (empty unless `keep_errors: true`)."
  @spec get_errors() :: [{String.t(), integer(), atom(), term()}]
  def get_errors() do
    @errors_table
    |> :ets.tab2list()
    |> Enum.map(fn {{host, port}, stage, reason} -> {host, port, stage, reason} end)
  end

  @doc """
  Counts one finished unit of the given kind (`:ok`, `:error` or `:resource_error`).
  """
  @spec incr(:ok | :error | :resource_error, non_neg_integer()) :: :ok
  def incr(kind, partition_index) do
    counters = counters()
    :counters.add(counters, Map.fetch!(@slots, kind), 1)
    :counters.add(counters, @partition_offset + partition_index + 1, 1)
  end

  @spec progress() :: %{
          done: non_neg_integer(),
          ok: non_neg_integer(),
          error: non_neg_integer(),
          resource_error: non_neg_integer()
        }
  def progress() do
    counters = counters()
    ok = :counters.get(counters, @slots.ok)
    error = :counters.get(counters, @slots.error)
    resource_error = :counters.get(counters, @slots.resource_error)

    %{done: ok + error + resource_error, ok: ok, error: error, resource_error: resource_error}
  end

  def partition_done(partition_index) do
    :counters.get(counters(), @partition_offset + partition_index + 1)
  end

  def get_finished() do
    @table_name
    |> :ets.tab2list()
    |> Enum.map(fn {_id, info} -> info end)
  end

  defp counters(), do: :persistent_term.get(@counters_key)
end
