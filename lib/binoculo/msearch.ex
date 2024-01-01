defmodule Binoculo.Msearch do
  @moduledoc """
  Handle msearch operations
  """

  require Logger
  alias Binoculo.Util

  @index "hosts"

  def create_index(_options) do
    Meilisearch.Indexes.create(@index, primary_key: "id")
  end

  def delete_index(_options) do
    Meilisearch.Indexes.delete(@index)
  end

  def save(payload) do
    payload =
      if payload[:port] in Util.get_possible_http_ports() do
        http_response = Util.format_http_response(payload[:response])

        Map.put(
          payload,
          :http_response,
          http_response
        )
      else
        payload
      end

    case Meilisearch.Documents.add_or_replace(@index, payload) do
      {:ok, response} ->
        {:ok, response}

      {:error, _code, response} ->
        {:error, response}
    end
  end

  def search(payload, options) do
    Meilisearch.Search.search(@index, payload, options)
  end

  def search_by_id(id) do
    Meilisearch.Documents.get(@index, id)
  end
end
