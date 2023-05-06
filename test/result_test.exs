defmodule ResultTest do
  use ExUnit.Case

  alias BinoculoDaemon.Results

  setup do
    Results.init_db()
    :ok
  end

  describe "test db init/remove" do
    test "db should be already started" do
      assert Results.is_started?()
    end

    test "should remove db from memory" do
      Results.delete_db()
      refute Results.is_started?()
    end
  end

  describe "crud workers progress/results" do
    test "should add and return progress / results" do
      host_info_ut = %{host: "127.0.0.1", port: 21_210}
      assert Results.add_item(host_info_ut) == :ok
      assert Results.get_qty_running() == 1
      assert Results.get_finished() == []

      running = Results.get_running() |> Enum.map(fn %{host: host} -> host end)
      assert host_info_ut.host in running
    end

    test "should finish and remove item from progress" do
      host_info_ut = %{host: "127.0.0.1", port: 21_210}
      Results.add_item(host_info_ut)
      Results.remove_item(host_info_ut)

      finished =
        Results.get_finished()
        |> Enum.filter(fn %{host: host} -> host == host_info_ut[:host] end)
        |> Enum.map(&(&1[:host]))

      assert Results.get_qty_running() == 0
      assert host_info_ut.host in finished
    end
  end
end
