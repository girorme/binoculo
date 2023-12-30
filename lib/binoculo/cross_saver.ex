defmodule Binoculo.CrossSaver do
  @moduledoc """
  Save to multiple sources
  """

  alias Binoculo.{Config, Results, Util}

  def save_results() do
    check_and_save_to_file()
  end

  defp check_and_save_to_file() do
    save_to_file_enabled?()
    |> save_to_file()
  end

  defp save_to_file_enabled?(), do: Application.get_env(:binoculo, :save_to_file, false)

  defp save_to_file(false), do: :noop

  defp save_to_file(true) do
    results =
      Results.get_finished()
      |> Enum.map(&Util.host_info_to_text_template/1)

    Config.get_output_file()
    |> File.write(results, [:append])
  end

  defp save_to_file(response) when is_binary(response) do
    String.to_atom(response)
    |> save_to_file()
  end
end
