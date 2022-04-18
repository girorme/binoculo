defmodule Binoculo.MixProject do
  use Mix.Project

  def project do
    [
      app: :binoculo,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:iplist, "~> 1.0.0"},
      {:cidr, ">= 1.1.0"}
    ]
  end

  defp escript do
    [
      main_module: Binoculo.CLI,
      path: 'bin/binoculo'
    ]
  end
end
