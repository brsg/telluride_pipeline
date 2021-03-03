defmodule TelluridePipeline.MixProject do
  use Mix.Project

  def project do
    [
      app: :telluride_pipeline,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {TelluridePipeline.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:flow, "~> 1.0"},
      {:broadway, "~> 0.6"},
      {:broadway_rabbitmq, "~> 0.6"},
      {:json, "~> 1.2"},
      {:ring_buffer, git: "https://github.com/brsg/ring_buffer.git", tag: "v0.0.1"}
    ]
  end
end
