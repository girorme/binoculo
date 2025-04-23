# Stage 1: Build the application
FROM elixir:1.18.3 AS builder

# Set the working directory inside the container
WORKDIR /app

ENV MIX_ENV=prod

# Build escript app
COPY lib ./lib
COPY mix.exs .
COPY mix.lock .
RUN mix local.rebar --force \
    && mix local.hex --force \
    && mix deps.get \
    && mix escript.build

# Stage 2: Create the final lightweight image
FROM elixir:1.18.3-alpine

# Install tini
RUN apk add --no-cache tini

# Set the working directory inside the container
WORKDIR /app

RUN mkdir output/
RUN chmod 777 output/

# Copy from builder stage
COPY --from=builder /app/bin/binoculo /app/bin/binoculo

# Use tini as the entrypoint
ENTRYPOINT ["/sbin/tini", "--", "/app/bin/binoculo"]
CMD ["--help"]
