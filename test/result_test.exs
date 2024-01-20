defmodule ResultTest do
  use ExUnit.Case

  alias Binoculo.Results

  setup do
    Results.init_db()
    :ok
  end

  describe "crud workers progress/results" do
    test "should add and return progress / results" do
      host_info_ut = %{host: "127.0.0.1", port: 21_210}
      assert Results.add_item(host_info_ut) == :ok

      running = Results.get_running() |> Enum.map(fn %{host: host} -> host end)
      assert host_info_ut.host in running
    end

    test "should finish and remove item from progress" do
      host_info_ut = %{host: "127.0.0.1", port: 21_210}
      Results.add_item(host_info_ut)
      Results.finish_item(host_info_ut)

      finished =
        Results.get_finished()
        |> Enum.map(& &1[:host])

      assert host_info_ut.host in finished
    end

    test "should remove specified finished item from progress" do
      host_info_ut = %{host: "127.0.0.1", port: 21_210}
      Results.add_item(host_info_ut)
      Results.finish_item(host_info_ut)

      finished =
        Results.get_finished()
        |> Enum.map(& &1[:host])

      assert host_info_ut.host in finished
    end
  end

  describe "db lifecycle" do
    test "should db start initalized" do
      assert Results.is_started?() == true
    end

    test "should destroy db" do
      Results.delete_db()
      assert Results.is_started?() == false
    end
  end
end
