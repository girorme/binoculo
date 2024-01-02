defmodule Binoculo.CrossSaver do
  @moduledoc """
  Save to multiple sources
  """

  alias Binoculo.{Config, Results, Util}

  # TODO: Add save to msearch

  def save_results() do
    check_and_save_to_file()
  end

  defp check_and_save_to_file() do
    save_to_file_enabled?()
    |> save_to_file()
  end

  defp save_to_file_enabled?(), do: String.trim(System.get_env("SAVE_TO_FILE"))

  defp save_to_file(response) when is_binary(response) do
    String.to_atom(response)
    |> save_to_file()
  end

  defp save_to_file(false), do: :noop

  defp save_to_file(true) do
    results =
      Results.get_finished()
      |> check_and_filter_read_payload()

    results = Enum.map(results, &Util.host_info_to_text_template/1)

    Config.get_output_file()
    |> File.write(results, [:append])
  end

  defp check_and_filter_read_payload(results) do
    case Config.get_read_payload() do
      nil ->
        results

      read_payload ->
        Enum.filter(results, fn %{response: response} ->
          Regex.match?(~r/#{read_payload}/i, response)
        end)
    end
  end
end
