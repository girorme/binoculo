defmodule PlannerTest do
  use ExUnit.Case, async: true

  alias Binoculo.Planner

  describe "build/3" do
    test "should count hosts and units without materializing the range" do
      assert {:ok, plan} = Planner.build("10.0.0.0/16", [80, 443])
      assert 65_536 == plan.total_hosts
      assert 131_072 == plan.total_units
    end

    test "should count single ip, cidr and ip range" do
      assert {:ok, %{total_hosts: 1}} = Planner.build("192.168.0.1", [80])
      assert {:ok, %{total_hosts: 256}} = Planner.build("192.168.0.1/24", [80])
      assert {:ok, %{total_hosts: 11}} = Planner.build("192.168.0.1..192.168.0.11", [80])
    end

    test "should plan a /0 instantly" do
      {micros, {:ok, plan}} = :timer.tc(fn -> Planner.build("0.0.0.0/0", [80, 22, 21]) end)

      assert 4_294_967_296 * 3 == plan.total_units
      assert micros < 100_000
    end

    test "should use the normalized network address as first host" do
      {:ok, plan} = Planner.build("177.67.56.60/16", [22], partitions: 1)
      [partition] = plan.partitions

      assert {"177.67.0.0", 22} == plan |> Planner.targets(partition) |> Enum.at(0)
      assert {"177.67.255.255", 22} == plan |> Planner.targets(partition) |> Enum.at(65_535)
    end

    test "should split units and concurrency across partitions" do
      {:ok, plan} = Planner.build("10.0.0.0/24", [80, 443], partitions: 8, concurrency: 100)

      assert 8 == length(plan.partitions)
      assert 512 == plan.partitions |> Enum.map(& &1.len) |> Enum.sum()
      # concurrency is split, never exceeded
      assert 100 == plan.partitions |> Enum.map(& &1.concurrency) |> Enum.sum()
    end

    test "should not create more partitions than units" do
      {:ok, plan} = Planner.build("192.168.0.1", [80], partitions: 8)
      assert [%{index: 0, start: 0, len: 1}] = plan.partitions
    end

    test "should not create more partitions than concurrency" do
      {:ok, plan} = Planner.build("10.0.0.0/24", [80], partitions: 8, concurrency: 3)

      assert 3 == length(plan.partitions)
      assert [1, 1, 1] == Enum.map(plan.partitions, & &1.concurrency)
    end

    test "should reject invalid options" do
      assert {:error, _} = Planner.build("10.0.0.0/24", [80], concurrency: 0)
      assert {:error, _} = Planner.build("10.0.0.0/24", [80], partitions: -1)
      assert {:error, _} = Planner.build("10.0.0.0/24", [80], timeout: 0)
      assert {:error, _} = Planner.build("10.0.0.0/24", [])
      assert {:error, _} = Planner.build("not-an-ip", [80])
      assert {:error, _} = Planner.build("192.168.0.10..192.168.0.1", [80])
    end
  end

  describe "concurrency_for/1" do
    test "should be capped at 1000 when the open files limit is high" do
      assert 1000 == Planner.concurrency_for(1_048_576)
      assert 1000 == Planner.concurrency_for(:infinity)
      assert 1000 == Planner.concurrency_for(:unknown)
    end

    test "should leave room for the descriptors the VM uses when the limit is low" do
      assert 768 == Planner.concurrency_for(1024)
      assert 1 == Planner.concurrency_for(100)
    end

    test "default_concurrency/0 never exceeds the cap" do
      assert Planner.default_concurrency() in 1..1000
    end
  end

  describe "split/2" do
    test "should be balanced, contiguous and cover every unit exactly once" do
      for n <- [1, 2, 7, 100, 131_072], p <- [1, 2, 3, 8, 13], p <= n do
        slices = Planner.split(n, p)
        lens = Enum.map(slices, &elem(&1, 1))

        assert p == length(slices)
        assert n == Enum.sum(lens)
        assert Enum.max(lens) - Enum.min(lens) <= 1

        covered =
          Enum.flat_map(slices, fn {start, len} -> Enum.to_list(start..(start + len - 1)) end)

        assert Enum.to_list(0..(n - 1)) == covered
      end
    end
  end

  describe "targets/2" do
    test "should keep all ports of a host adjacent and cover every target once" do
      {:ok, plan} = Planner.build("10.0.0.0/30", [22, 80], partitions: 3)

      targets = Enum.flat_map(plan.partitions, &Enum.to_list(Planner.targets(plan, &1)))

      assert [
               {"10.0.0.0", 22},
               {"10.0.0.0", 80},
               {"10.0.0.1", 22},
               {"10.0.0.1", 80},
               {"10.0.0.2", 22},
               {"10.0.0.2", 80},
               {"10.0.0.3", 22},
               {"10.0.0.3", 80}
             ] == targets
    end
  end
end
