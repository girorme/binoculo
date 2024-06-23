defmodule Binoculo.Refiner do
  def find_occurrences_in_responses(patterns, responses) when is_list(patterns) do
    Enum.filter(responses, fn %{response: response} ->
      Enum.all?(patterns, fn pattern -> String.contains?(response, pattern) end)
    end)
  end

  def find_occurrences_in_responses(pattern, responses) do
    Enum.filter(responses, fn %{response: response} ->
      String.contains?(response, pattern)
    end)
  end
end
