defmodule ArgsTest do
  use ExUnit.Case, async: true

  alias Binoculo.Args

  describe "parse_args/1" do
    test "should parse valid args" do
      args = ["--range", "192.168.101.1", "-p", "80", "--output", "my_file.txt"]
      assert {:ok, parsed_args} = Args.parse_args(args)

      parsed_args = parsed_args |> Map.from_struct()

      assert %{options: %{host_notation: "192.168.101.1", ports: [80], output: "my_file.txt"}} =
               parsed_args
    end

    test "should parse read payload with one pattern" do
      args = ["--range", "192.168.101.1", "-p", "80", "--read", "nginx"]
      assert {:ok, parsed_args} = Args.parse_args(args)

      parsed_args =
        parsed_args
        |> Map.from_struct()

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
      assert {:ok, parsed_args} = Args.parse_args(args)

      parsed_args =
        parsed_args
        |> Map.from_struct()

      assert %{
               options: %{
                 host_notation: "192.168.101.1",
                 ports: [80],
                 read: ["nginx", "php"]
               }
             } = parsed_args
    end

    test "should parse valid port ranges" do
      args = ["--range", "192.168.101.1", "-p", "80-85", "--output", "my_file.txt"]
      args2 = ["--range", "192.168.101.1", "-p", "80,81", "--output", "my_file.txt"]

      assert {:ok, _parsed_args} = Args.parse_args(args)
      assert {:ok, _parsed_args} = Args.parse_args(args2)
    end

    test "should fail when invalid port range" do
      args = ["--range", "192.168.101.1", "-p", "81-80", "--output", "my_file.txt"]
      assert {:error, _invalid_message} = Args.parse_args(args)
    end

    test "should fail when invalid cidr/notation and port" do
      args = ["--range", "192.168.101.x", "-p", "80", "--output", "my_file.txt"]
      assert {:error, _invalid_message} = Args.parse_args(args)

      args = ["--range", "192.168.101.1", "-p", "invalid_port", "--output", "my_file.txt"]
      assert {:error, _invalid_message} = Args.parse_args(args)
    end
  end
end
