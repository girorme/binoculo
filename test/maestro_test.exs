defmodule MaestroTest do
  use ExUnit.Case, async: false

  alias Binoculo.{Config, Maestro, Planner, Results}
  alias Binoculo.Stub.Server

  @open_ports [31_001, 31_002, 31_003]
  @closed_port 31_009

  setup_all do
    pids = Enum.map(@open_ports, &spawn(Server, :start, [&1, "banner #{&1}"]))
    :timer.sleep(100)
    on_exit(fn -> Enum.each(pids, &Process.exit(&1, :kill)) end)
    :ok
  end

  defp plan!(host, ports, opts) do
    # Config is global: other tests leave a write payload behind, which makes the stub
    # close with unread data (RST) and drops the banner
    Config.set_write_payload(%{write_payload: nil})
    nil = Config.get_write_payload()

    {:ok, plan} = Planner.build(host, ports, opts)
    Results.init_db(length(plan.partitions))
    plan
  end

  defp found(), do: Results.get_finished() |> Enum.map(&{&1.host, &1.port}) |> Enum.sort()

  describe "run/2 with real sockets" do
    test "should return the same results with 1 or many partitions" do
      ports = @open_ports ++ [@closed_port]

      plan = plan!("127.0.0.1", ports, partitions: 1, timeout: 500)
      assert %{failed_partitions: [], not_processed: 0} = Maestro.run(plan)
      single = found()

      plan = plan!("127.0.0.1", ports, partitions: 4, timeout: 500)
      assert %{failed_partitions: [], not_processed: 0} = Maestro.run(plan)

      assert single == found()
      assert Enum.map(@open_ports, &{"127.0.0.1", &1}) == single
    end

    test "should save every open port of the same host and count all units" do
      plan = plan!("127.0.0.1", @open_ports ++ [@closed_port], partitions: 2, timeout: 500)
      Maestro.run(plan)

      assert %{done: 4, ok: 3, error: 1, resource_error: 0} = Results.progress()
      assert Enum.all?(Results.get_finished(), &(&1.response =~ "banner #{&1.port}"))
    end

    test "should finish when every unit fails" do
      plan = plan!("127.0.0.0/29", [@closed_port], partitions: 3, timeout: 500)

      assert %{failed_partitions: [], not_processed: 0} = Maestro.run(plan)
      assert %{done: 8, ok: 0, error: 8} = Results.progress()
      assert [] == Results.get_finished()
    end
  end

  describe "run/2 with a fake scan function" do
    test "should never exceed the configured concurrency" do
      limit = 10
      plan = plan!("10.0.0.0/24", [80, 81], partitions: 4, concurrency: limit, timeout: 500)

      running = :atomics.new(1, [])
      peak = :atomics.new(1, [])

      scan_fun = fn host, port, _timeout, _opts ->
        now = :atomics.add_get(running, 1, 1)
        update_peak(peak, now)
        Process.sleep(5)
        :atomics.sub(running, 1, 1)
        {:ok, %{host: host, port: port, response: "x"}}
      end

      Maestro.run(plan, scan_fun: scan_fun)

      assert %{done: 512, ok: 512} = Results.progress()
      assert :atomics.get(peak, 1) <= limit
      assert :atomics.get(peak, 1) > 1
    end

    test "should count local resource errors apart from unreachable hosts" do
      plan = plan!("10.0.0.0/30", [80], partitions: 2, timeout: 500)

      scan_fun = fn host, port, _timeout, _opts ->
        reason = if host == "10.0.0.0", do: :emfile, else: :econnrefused
        {:error, %{host: host, port: port, reason: reason, response: ""}}
      end

      Maestro.run(plan, scan_fun: scan_fun)

      assert %{done: 4, resource_error: 1, error: 3} = Results.progress()
    end

    test "should break errors down by stage and reason" do
      plan = plan!("10.0.0.0/30", [80], partitions: 2, timeout: 500)

      scan_fun = fn host, port, _timeout, _opts ->
        {stage, reason} =
          if host == "10.0.0.0", do: {:recv, :timeout}, else: {:connect, :econnrefused}

        {:error, %{host: host, port: port, stage: stage, reason: reason, response: ""}}
      end

      Maestro.run(plan, scan_fun: scan_fun)

      assert [{:connect, :econnrefused, 3}, {:recv, :timeout, 1}] = Results.error_breakdown()
    end

    test "should survive exceptions in a unit" do
      plan = plan!("10.0.0.0/30", [80], partitions: 1, timeout: 500)
      scan_fun = fn _host, _port, _timeout, _opts -> raise "boom" end

      assert %{failed_partitions: []} = Maestro.run(plan, scan_fun: scan_fun)
      assert %{done: 4, error: 4} = Results.progress()
    end

    test "should isolate a crashed partition and report what was not processed" do
      plan = plan!("10.0.0.0/28", [80], partitions: 4, concurrency: 4, timeout: 500)

      # kills the unit (and its linked partition) on the first target of the last partition
      scan_fun = fn host, port, _timeout, _opts ->
        if host == "10.0.0.12", do: Process.exit(self(), :kill)
        {:ok, %{host: host, port: port, response: "x"}}
      end

      assert %{failed_partitions: [3], not_processed: not_processed} =
               Maestro.run(plan, scan_fun: scan_fun)

      assert not_processed >= 1
      assert 16 - not_processed == Results.progress().done
      assert Results.partition_done(0) == 4
    end

    test "should count a unit that exceeds its timeout as error" do
      plan = plan!("10.0.0.0/30", [80], partitions: 1, timeout: 10)

      scan_fun = fn host, port, _timeout, _opts ->
        if host == "10.0.0.0", do: Process.sleep(:infinity)
        {:ok, %{host: host, port: port, response: "x"}}
      end

      assert %{failed_partitions: []} = Maestro.run(plan, scan_fun: scan_fun)
      assert %{done: 4, ok: 3, error: 1} = Results.progress()
    end
  end

  defp update_peak(peak, now) do
    current = :atomics.get(peak, 1)

    if now > current and :atomics.compare_exchange(peak, 1, current, now) != :ok do
      update_peak(peak, now)
    end
  end
end
