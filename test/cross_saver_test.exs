defmodule CrossSaverTest do
  use ExUnit.Case, async: true

  alias Binoculo.{CrossSaver, Config, Results}

  @output_file "output/sut_result"

  setup do
    Results.init_db()
    :ok
  end

  describe "save_results/0" do
    test "should save results to file" do
      Config.set_output_file(%{output_file: "sut_result"})
      assert :ok = CrossSaver.save_results()
      assert File.exists?(@output_file)

      on_exit(fn ->
        File.rm(@output_file)
      end)
    end

    test "should save results and check read payload" do
      Config.set_read_payload(%{read_payload: "Apache"})
      assert :ok = CrossSaver.save_results()
    end
  end
end
