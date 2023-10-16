defmodule BinoculoDaemon.Msearch do
  @index "hosts"

  def create_index(_options) do
    Meilisearch.Indexes.create(@index, primary_key: "id")
  end

  def delete_index(_options) do
    Meilisearch.Indexes.delete(@index)
  end

  def save(payload) do
    case Meilisearch.Documents.add_or_replace(@index, payload) do
      {:ok, response} -> {:ok, response}
      {:error, _code, response} -> {:error, response}
    end
  end

  def search(payload, options) do
    Meilisearch.Search.search(@index, payload, options)
  end

  def search_by_id(id) do
    Meilisearch.Documents.get(@index, id)
  end
end
