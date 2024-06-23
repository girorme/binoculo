defmodule ArgsTest do
  use ExUnit.Case, async: true

  alias Binoculo.Args

  describe "parse_args/1" do
    test "should parse valid args" do
      args = ["--range", "192.168.101.1", "-p", "80", "--output", "my_file.txt"]
      parsed_args = Args.parse_args(args) |> Map.from_struct()

      assert %{options: %{host_notation: "192.168.101.1", ports: [80], output: "my_file.txt"}} =
               parsed_args
    end

    test "should parse read payload with one pattern" do
      args = ["--range", "192.168.101.1", "-p", "80", "--read", "nginx"]
      parsed_args = Args.parse_args(args) |> Map.from_struct()

      assert %{
               options: %{
                 host_notation: "192.168.101.1",
                 ports: [80],
                 read: "nginx"
               }
             } = parsed_args
    end

    test "should parse read payload with multiple patterns" do
      args = ["--range", "192.168.101.1", "-p", "80", "--read", "nginx,php"]
      parsed_args = Args.parse_args(args) |> Map.from_struct()

      assert %{
               options: %{
                 host_notation: "192.168.101.1",
                 ports: [80],
                 read: ["nginx", "php"]
               }
             } = parsed_args
    end
  end
end
