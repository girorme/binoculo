defmodule Binoculo.Maestro do
  @moduledoc """
  Runs a scan plan: every partition scans its slice in parallel with its own
  concurrency limit and writes straight to `Binoculo.Results` (no central mailbox).

  `Binoculo.Results.init_db/1` must be called by the caller before `run/2`.
  """

  alias Binoculo.{Config, Planner, Results, Worker}

  # connection errors caused by this machine's limits, not by the target
  @resource_errors [:emfile, :enfile, :eaddrnotavail]

  @doc """
  Scans every unit of the plan and waits for all partitions.

  A crashed partition does not stop the others; it is reported in
  `:failed_partitions` and its unscanned units in `:not_processed`.

  Options: `:scan_fun` - `(host, port, timeout, opts -> {:ok, map} | {:error, map})`
  (default `Binoculo.Worker.get_banner/4`).
  """
  @spec run(Planner.t(), keyword()) :: %{
          failed_partitions: [non_neg_integer()],
          not_processed: non_neg_integer()
        }
  def run(%Planner{} = plan, opts \\ []) do
    scan_fun = Keyword.get(opts, :scan_fun, &Worker.get_banner/4)
    scan_opts = [write_payload: Config.get_write_payload()]

    results =
      Task.Supervisor.async_stream_nolink(
        Binoculo.TaskSupervisor,
        plan.partitions,
        &run_partition(plan, &1, scan_fun, scan_opts),
        max_concurrency: length(plan.partitions),
        timeout: :infinity,
        ordered: true
      )

    plan.partitions
    |> Enum.zip(results)
    |> Enum.reduce(%{failed_partitions: [], not_processed: 0}, fn
      {_partition, {:ok, :ok}}, acc ->
        acc

      {%{index: index, len: len}, {:exit, _reason}}, acc ->
        %{
          failed_partitions: acc.failed_partitions ++ [index],
          not_processed: acc.not_processed + len - Results.partition_done(index)
        }
    end)
  end

  defp run_partition(plan, %{index: index, concurrency: concurrency} = partition, scan_fun, opts) do
    plan
    |> Planner.targets(partition)
    |> Task.async_stream(
      fn {host, port} -> scan_unit(host, port, index, plan.timeout, scan_fun, opts) end,
      max_concurrency: concurrency,
      # connect + recv, each bounded by the plan timeout
      timeout: 2 * plan.timeout + 1_000,
      on_timeout: :kill_task,
      ordered: false
    )
    |> Enum.each(fn
      {:ok, _} ->
        :ok

      {:exit, :timeout} ->
        Results.put_error(%{stage: :unit, reason: :timeout})
        Results.incr(:error, index)
    end)
  end

  defp scan_unit(host, port, index, timeout, scan_fun, opts) do
    case safe_scan(scan_fun, host, port, timeout, opts) do
      {:ok, info} ->
        Results.put_result(info)
        Results.incr(:ok, index)

      {:error, %{reason: reason} = info} when reason in @resource_errors ->
        Results.put_error(info)
        Results.incr(:resource_error, index)

      {:error, info} ->
        Results.put_error(info)
        Results.incr(:error, index)
    end
  end

  # an exception in one unit must not take the whole partition down
  defp safe_scan(scan_fun, host, port, timeout, opts) do
    scan_fun.(host, port, timeout, opts)
  rescue
    _ -> {:error, %{host: host, port: port, stage: :unit, reason: :exception}}
  end
end
