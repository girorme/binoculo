defmodule Binoculo.Application do
  @moduledoc """
  Main application
  """
  use Application

  alias Binoculo.Config

  @impl true
  def start(_type, _args) do
    children = [
      {Config, %{}}
    ]

    opts = [strategy: :one_for_one, name: Binoculo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
