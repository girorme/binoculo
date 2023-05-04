defmodule WorkerTest do
  @moduledoc """
  Main worker (get_banner) tests
  """
  use ExUnit.Case, async: true

  alias BinoculoDaemon.Worker
  alias BinoculoDaemon.Stub.Server

  setup_all do
    spawn(Server, :start, [21_210])
    :ok
  end

  describe "Testing the banner grab function" do
    test "get banner passing ip + port" do
      {:ok, response} = Worker.get_banner("127.0.0.1", 21_210)
      assert response =~ ~r/ftp/i
    end

    test "get error and reason when port is not open in host" do
      {:error, response} = Worker.get_banner("127.0.0.1", 9999)
      assert response =~ ~r/Error returning banner/i
    end

    test "get error and reason when host is not reachable" do
      {:error, response} = Worker.get_banner("1.1.1.1", 9999)
      assert response =~ ~r/Error returning banner/i
    end
  end
end
