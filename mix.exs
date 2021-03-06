defmodule Spectre.MixProject do
  use Mix.Project

  def project do
    [
      app: :spectre,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end 
  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :dialyzer]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.0.0-rc.4", runtime: false},
      # {:ex_types, path: "../ex_types"}
      {:ex_types, git: "git@github.com:the-mikedavis/ex_types.git"}
    ]
  end
end
