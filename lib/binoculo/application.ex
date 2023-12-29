defmodule Binoculo.Application do
  @moduledoc """
  Main application
  """
  use Application

  alias Binoculo.{Config, Maestro}

  @impl true
  def start(_type, _args) do
    children = [
      {Config, %{}}
    ]

    children =
      if System.get_env("PROD") do
        children ++ [Maestro]
      else
        children
      end

    opts = [strategy: :one_for_one, name: Binoculo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
