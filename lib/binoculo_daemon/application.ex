defmodule BinoculoDaemon.Application do
  @moduledoc """
  Main application
  """
  use Application

  alias BinoculoDaemon.Maestro

  @impl true
  def start(_type, _args) do
    children =
      unless Mix.env() == :test do
        [Maestro]
      else
        []
      end

    opts = [strategy: :one_for_one, name: BinoculoDaemon.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
