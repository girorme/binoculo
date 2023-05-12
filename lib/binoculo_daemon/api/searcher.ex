defmodule BinoculoDaemon.Api.Searcher do
  @moduledoc """
  Api to searchers (elasticsearh, meilisearch, etc)
  """
  @type index() :: String.t()
  @type payload() :: map()
  @type options() :: map()

  @callback create_index(index(), options()) :: {atom(), any()}
  @callback delete_index(index(), options()) :: {atom(), any()}
  @callback save(index(), payload()) :: {atom(), any()}
  @callback search(index(), payload()) :: {atom(), any()}
end
