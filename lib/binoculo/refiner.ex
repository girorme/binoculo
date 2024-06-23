defmodule Binoculo.Refiner do
  def find_occurrences_in_responses(pattern, responses) do
    pattern = prepare_pattern(pattern)

    Enum.filter(responses, fn %{response: response} ->
      Regex.match?(~r/#{pattern}/i, response)
    end)
  end

  defp prepare_pattern(pattern) when is_list(pattern) do
    Enum.map(pattern, fn part ->
      "(?=.*#{part})"
    end)
    |> Enum.join()
  end

  defp prepare_pattern(pattern), do: pattern
end
