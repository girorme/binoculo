import Config

config :meilisearch,
  endpoint: "http://meilisearch:7700"

import_config "#{Mix.env()}.exs"
