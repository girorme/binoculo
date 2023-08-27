defmodule BinoculoDaemon.Api.Searcher do
  @moduledoc """
  Api to searchers (elasticsearh, meilisearch, etc)
  """
  @type index() :: String.t()
  @type payload() :: term()
  @type options() :: map() | keyword()
  @type default_response() :: any()

  @callback create_index(options()) :: default_response()
  @callback delete_index(options()) :: default_response()
  @callback save(payload()) :: default_response()
  @callback search(payload(), options()) :: default_response()
end
