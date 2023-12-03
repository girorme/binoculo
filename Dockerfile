FROM bitwalker/alpine-elixir:latest

WORKDIR /app

COPY bin/binoculo /app/bin/binoculo
COPY binoculo /app/binoculo.sh

# Set the entry point and command to run when the container starts
ENTRYPOINT ["/bin/bash", "binoculo.sh"]

# If no command or options are provided, run the default -h help command
CMD ["-h"] 
