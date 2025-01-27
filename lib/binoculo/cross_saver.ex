defmodule Binoculo.CrossSaver do
  @moduledoc """
  Save to multiple sources
  """

  alias Binoculo.{Config, Msearch, Refiner, Results, Util}

  def save_results() do
    check_and_save_to_file()
    check_and_save_to_msearch()
  end

  defp check_and_save_to_file() do
    save_to_file_enabled?()
    |> save_to_file()
  end

  def save_to_file_enabled?(), do: true

  defp save_to_file(true) do
    results =
      Results.get_finished()
      |> check_and_filter_read_payload()

    results = Enum.map(results, &Util.host_info_to_text_template/1)

    # check if output dir exists and create it if not
    File.mkdir_p!("output")

    Config.get_output_file()
    |> then(fn file -> "output/#{file}" end)
    |> File.write(results, [:append])
  end

  defp check_and_save_to_msearch() do
    save_to_msearch_enabled?()
    |> save_to_msearch()
  end

  # TODO: Add save to msearch flag
  defp save_to_msearch_enabled?(), do: true

  defp save_to_msearch(true) do
    results =
      Results.get_finished()
      |> check_and_filter_read_payload()

    Enum.each(results, &Msearch.save/1)

    :ok
  end

  defp check_and_filter_read_payload(results) do
    case Config.get_read_payload() do
      nil ->
        results

      read_payload ->
        Refiner.find_occurrences_in_responses(read_payload, results)
    end
  end
end
