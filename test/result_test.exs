defmodule ResultTest do
  use ExUnit.Case, async: false

  alias Binoculo.Results

  setup do
    Results.init_db(2)
    :ok
  end

  describe "results" do
    test "should store a result with the meilisearch id" do
      assert :ok = Results.put_result(%{host: "127.0.0.1", port: 21_210, response: "ftp"})

      assert [%{host: "127.0.0.1", port: 21_210, response: "ftp", id: id}] =
               Results.get_finished()

      assert id == :crypto.hash(:md5, "127.0.0.1 <> 21210") |> Base.encode16()
    end

    test "should replace the result of the same host and port" do
      Results.put_result(%{host: "127.0.0.1", port: 80, response: "old"})
      Results.put_result(%{host: "127.0.0.1", port: 80, response: "new"})
      Results.put_result(%{host: "127.0.0.1", port: 81, response: "other"})

      assert 2 == length(Results.get_finished())
    end

    test "should keep many results with constant cost per insert" do
      {micros, _} =
        :timer.tc(fn ->
          for port <- 1..50_000, do: Results.put_result(%{host: "10.0.0.1", port: port})
        end)

      assert 50_000 == length(Results.get_finished())
      # the old list based store was quadratic and took minutes for this size
      assert micros < 5_000_000
    end
  end

  describe "errors" do
    test "should count by stage and reason, most frequent first" do
      Results.put_error(%{host: "10.0.0.1", port: 22, stage: :connect, reason: :timeout})
      Results.put_error(%{host: "10.0.0.2", port: 22, stage: :connect, reason: :timeout})
      Results.put_error(%{host: "10.0.0.3", port: 22, stage: :recv, reason: :closed})

      assert [{:connect, :timeout, 2}, {:recv, :closed, 1}] == Results.error_breakdown()
    end

    test "should not keep failed hosts unless enabled" do
      Results.put_error(%{host: "10.0.0.1", port: 22, stage: :connect, reason: :timeout})
      assert [] == Results.get_errors()

      Results.init_db(1, keep_errors: true)
      Results.put_error(%{host: "10.0.0.1", port: 22, stage: :connect, reason: :timeout})
      Results.put_error(%{stage: :unit, reason: :timeout})

      assert [{"10.0.0.1", 22, :connect, :timeout}] == Results.get_errors()

      assert [{:connect, :timeout, 1}, {:unit, :timeout, 1}] |> Enum.sort() ==
               Results.error_breakdown() |> Enum.sort()
    end
  end

  describe "progress" do
    test "should start zeroed" do
      assert %{done: 0, ok: 0, error: 0, resource_error: 0} == Results.progress()
    end

    test "should count by kind and by partition" do
      Results.incr(:ok, 0)
      Results.incr(:ok, 1)
      Results.incr(:error, 1)
      Results.incr(:resource_error, 1)

      assert %{done: 4, ok: 2, error: 1, resource_error: 1} == Results.progress()
      assert 1 == Results.partition_done(0)
      assert 3 == Results.partition_done(1)
    end
  end

  describe "db lifecycle" do
    test "should db start initalized" do
      assert Results.is_started?() == true
    end

    test "should reset when initialized again" do
      Results.put_result(%{host: "127.0.0.1", port: 80})
      Results.incr(:ok, 0)

      Results.init_db()

      assert [] == Results.get_finished()
      assert 0 == Results.progress().done
    end

    test "should destroy db" do
      Results.delete_db()
      assert Results.is_started?() == false
    end
  end
end
