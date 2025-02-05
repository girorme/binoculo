#!/bin/bash

# Check if meilisearch is ready to facet results
status_code=$(curl --write-out "%{http_code}" --silent --output /dev/null \
  --request GET \
  --url http://localhost:7700/indexes/hosts/settings/filterable-attributes) # <- Closing parenthesis added here

# Check if the status code is not 200
if [ "$status_code" != "200" ]; then
  echo "Preparing meilisearch to facet results..."

  # Run the PUT request to update filterable attributes
  curl --silent --output /dev/null --write-out "" \
    --request PUT \
    --url http://localhost:7700/indexes/hosts/settings/filterable-attributes \
    --header 'Content-Type: application/json' \
    --data '[
      "http_response",
      "port",
      "response"
    ]'
else
  echo "Meilisearch is ready to facet results..."
fi
