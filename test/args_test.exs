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

    test "should use scan tuning defaults" do
      args = ["--range", "192.168.101.1", "-p", "80", "--output", "my_file.txt"]
      assert {:ok, %{options: options}} = Args.parse_args(args)

      assert Binoculo.Planner.default_concurrency() == options.concurrency
      assert Binoculo.Planner.default_timeout() == options.timeout
      assert 500 == options.timeout
      assert System.schedulers_online() == options.partitions
    end

    test "should parse scan tuning options" do
      args = [
        "--range",
        "192.168.101.1",
        "-p",
        "80",
        "--output",
        "my_file.txt",
        "--concurrency",
        "300",
        "--partitions",
        "4",
        "--timeout",
        "1500"
      ]

      assert {:ok, %{options: options}} = Args.parse_args(args)
      assert %{concurrency: 300, partitions: 4, timeout: 1500} = options
    end

    test "should accept an errors output file" do
      args = ["--range", "192.168.101.1", "-p", "80", "--errors-output", "errors.txt"]
      assert {:ok, %{options: %{errors_output: "errors.txt"}}} = Args.parse_args(args)
    end

    test "should fail with invalid scan tuning options" do
      base = ["--range", "192.168.101.1", "-p", "80", "--output", "my_file.txt"]

      for option <- ["--concurrency", "--partitions", "--timeout"], value <- ["0", "-1", "abc"] do
        assert {:error, _invalid_message} = Args.parse_args(base ++ [option, value])
      end
    end

    test "should fail when invalid cidr/notation and port" do
      args = ["--range", "192.168.101.x", "-p", "80", "--output", "my_file.txt"]
      assert {:error, _invalid_message} = Args.parse_args(args)

      args = ["--range", "192.168.101.1", "-p", "invalid_port", "--output", "my_file.txt"]
      assert {:error, _invalid_message} = Args.parse_args(args)
    end
  end
end
