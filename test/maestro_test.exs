defmodule MaestroTest do
  use ExUnit.Case, async: false

  alias Binoculo.{Maestro, Results}

  setup do
    Results.init_db()
    :ok
  end

  describe "start_get_banner_workers/2" do
    test "should start workers" do
      assert {:ok, _qty_to_run} = Maestro.start_get_banner_workers("127.0.0.1", [80])
    end
  end

  describe "handle_cast/2" do
    test "should start worker" do
      {:noreply, _state} = Maestro.handle_cast({:start_worker, %{host: "127.0.0.1", port: 80}}, %{})
    end
  end

  describe "handle_info/2" do
    test "should finish item" do
      {:noreply, _state} = Maestro.handle_info({self(), {:ok, %{host: "127.0.0.1", port: 80}}}, %{})
    end
  end
end
