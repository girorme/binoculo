defmodule ArgsWithEnvTest do
  use ExUnit.Case, async: false

  alias Binoculo.Args

  setup do
    put_prod_env_for_test()
  end

  describe "parse_args/1" do
    test "should work with env var != test" do


      args = ["--range", "192.168.101.1", "-p", "80", "--output", "my_file.txt"]
      assert {:ok, _parsed_args} = Args.parse_args(args)
    end
  end

  defp put_prod_env_for_test() do
    previous_value = System.get_env("MIX_ENV", "test")
    System.put_env("MIX_ENV", "prod")
    on_exit(fn -> System.put_env("MIX_ENV", previous_value) end)
  end
end
