defmodule BinoculoTest do
  use ExUnit.Case
  doctest Binoculo.CLI
  alias Binoculo.CLI, as: BinoculoClI

  test "No args" do
    assert BinoculoClI.main([]) == Binoculo.Util.help()
  end
end
