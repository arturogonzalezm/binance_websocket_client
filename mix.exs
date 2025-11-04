defmodule BinanceWebsocketClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :binance_websocket_client,
      version: "0.1.0",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),  # Add this line
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      xref: [exclude: [:crypto]],
      dialyzer: [
        plt_add_apps: [:mix],
        ignore_warnings: "dialyzer.ignore-warnings"
      ],
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {BinanceWebsocketClient.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:websockex, "~> 0.4.3"},
      {:jason, "~> 1.4"},
      {:phoenix, "~> 1.7"},
      {:phoenix_pubsub, "~> 2.1"},
      {:plug_cowboy, "~> 2.6"},
      {:mox, "~> 1.1.0", only: :test},
      {:credo, "~> 1.7.8", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

    # Mix 1.19+: Configure preferred CLI envs here (formerly :preferred_cli_env in project/0)
    def cli do
      [
        preferred_envs: [
          coveralls: :test,
          "coveralls.detail": :test,
          "coveralls.post": :test,
          "coveralls.html": :test,
          "coveralls.github": :test
        ]
      ]
    end
  end
