import Config

config :meilisearch,
  endpoint: "http://127.0.0.1:7700"

import_config "#{Mix.env()}.exs"
