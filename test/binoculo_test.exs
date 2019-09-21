defmodule BinoculoTest do
  use ExUnit.Case
  doctest Binoculo

  test "greets the world" do
    assert Binoculo.hello() == :world
  end
end
