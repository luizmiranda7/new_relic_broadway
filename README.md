# New Relic Broadway

[![Hex.pm Version](https://img.shields.io/hexpm/v/new_relic_broadway.svg)](https://hex.pm/packages/new_relic_broadway)

This package adds `Broadway` specific instrumentation on top of the `new_relic_agent` package. You may use all the built-in capabilities of the New Relic Agent!

Check out the agent for more:

* https://github.com/newrelic/elixir_agent
* https://hexdocs.pm/new_relic_agent

## Installation

Install the [Hex package](https://hex.pm/packages/new_relic_broadway)

```elixir
defp deps do
  [
    {:broadway, "~> 1.0.0"},
    {:new_relic_broadway, "~> 0.1"}
  ]
end
```

## Configuration

* You must configure `new_relic_agent` to authenticate to New Relic. Please see: https://github.com/newrelic/elixir_agent/#configuration

## Instrumentation

1) Add the Broadway Genserver to your supervisor tree

```elixir
defmodule MyApp.Application do
  @moduledoc false

  use Application
  def start(_type, args) do

    extra_children = Keyword.get(args, :extra_children, [])

    # List all child processes to be supervised
    children = [
      MyApp.Repo,
      NewRelicBroadway.Telemetry.Broadway,
      {Broadway, Application.get_env(:my_app, Broadway)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Broker.Supervisor]
    Supervisor.start_link(children ++ extra_children, opts)
  end
end
```
