import Config

config :binoculo,
  save_to_file: System.get_env("SAVE_TO_FILE") || false

config :meilisearch,
  endpoint: "http://localhost:7700"
