defmodule BinoculoDaemon.Application do
  @moduledoc """
  Main application
  """
  use Application

  alias BinoculoDaemon.Maestro

  @impl true
  def start(_type, _args) do
    children =
      if System.get_env("PROD") do
        [Maestro]
      else
        []
      end

    opts = [strategy: :one_for_one, name: BinoculoDaemon.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
