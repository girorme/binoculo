defmodule Binoculo.MixProject do
  use Mix.Project

  def project do
    [
      app: :binoculo,
      version: "1.0.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript(),
      releases: [
        binoculo: [
          steps: [:assemble, &Bakeware.assemble/1],
          strip_beams: Mix.env() == :prod,
          overwrite: true
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :cidr],
      mod: {Binoculo.CLI, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:iplist, "~> 1.0.0"},
      {:bakeware, path: "../bakeware", runtime: false}
    ]
  end

  defp escript do
    [
      main_module: Binoculo.CLI,
      path: 'bin/binoculo'
    ]
  end
end
