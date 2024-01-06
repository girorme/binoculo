defmodule ArgsTest do
  use ExUnit.Case, async: true

  alias Binoculo.Args

  describe "parse args" do
    test "should parse valid args" do
      args = ["--range", "192.168.101.1", "-p", "80", "--output", "my_file.txt"]
      parsed_args = Args.parse_args(args) |> Map.from_struct()

      assert %{options: %{host_notation: "192.168.101.1", ports: [80], output: "my_file.txt"}} =
               parsed_args
    end
  end
end
