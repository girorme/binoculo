defmodule RefinerTest do
  use ExUnit.Case, async: true

  alias Binoculo.Refiner

  @responses [
    %{response: "hello and world"},
    %{response: "world"},
    %{response: "test"},
    %{response: "test xoo"}
  ]

  describe "Refiner.find_occurrences_in_responses/2" do
    test "should find occurrences in responses with single pattern" do
      assert [%{response: "test"}, %{response: "test xoo"}] ==
               Refiner.find_occurrences_in_responses("test", @responses)
    end

    test "should find occurrences in responses with multiple patterns (AND)" do
      assert [%{response: "hello and world"}] ==
               Refiner.find_occurrences_in_responses(["hello", "world"], @responses)

      assert [%{response: "test xoo"}] ==
               Refiner.find_occurrences_in_responses(["xoo"], @responses)
    end
  end
end
