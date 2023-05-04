defmodule BinoculoDaemon.MixProject do
  use Mix.Project

  def project do
    [
      app: :binoculo_daemon,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {BinoculoDaemon.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:net_address, "~> 0.2.0"},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
