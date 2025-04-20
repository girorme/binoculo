defmodule Binoculo.MixProject do
  use Mix.Project

  def project do
    [
      app: :binoculo,
      version: "1.3.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls, ignore_modules: [Binoculo, Binoculo.Msearch]],
      preferred_cli_env: [coveralls: :test, "coveralls.html": :test],
      escript: escript()
    ]
  end

  def escript do
    [
      main_module: Binoculo,
      path: "bin/binoculo"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {Binoculo.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:net_address, "~> 0.2.0"},
      {:mox, "~> 1.0", only: :test},
      {:meilisearch, "~> 0.20.0"},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false},
      {:optimus, "~> 0.2"},
      {:progress_bar, "> 0.0.0"},
      {:excoveralls, "~> 0.18", only: :test},
      {:mock, "~> 0.3.0", only: :test},
      # Add this line
      {:plug_cowboy, "~> 2.5"},
      {:poison, "~> 6.0"}
    ]
  end
end
