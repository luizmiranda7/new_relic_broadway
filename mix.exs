defmodule NewRelicBroadway.MixProject do
  use Mix.Project

  def project do
    [
      app: :new_relic_broadway,
      description: "New Relic Instrumentation for BroaNewRelicBroadway",
      version: "0.0.1",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      name: "New Relic BroaNewRelicBroadway",
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      maintainers: ["Luiz Miranda"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/luizmiranda7/new_relic_broadway"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:new_relic_agent, "~> 1.19"},
      {:broadway, "~> 1.0.0", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
