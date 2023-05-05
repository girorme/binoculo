defmodule ResultTest do
  use ExUnit.Case, async: true

  alias BinoculoDaemon.Results

  setup_all do
    Results.init_db()
    :ok
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
  end
end
