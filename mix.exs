defmodule PhoenixTestPlaywright.MixProject do
  use Mix.Project

  @version "0.2.0"
  @source_url "https://github.com/ftes/phoenix_test_playwright"
  @description """
  Execute PhoenixTest cases in an actual browser via Playwright.
  """

  def project do
    [
      app: :phoenix_test_playwright,
      version: @version,
      description: @description,
      elixir: "~> 1.15",
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      name: "PhoenixTestPlaywright",
      source_url: @source_url,
      docs: docs(),
      aliases: aliases()
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
      {:esbuild, "~> 0.8", only: :test, runtime: false},
      {:ex_doc, "~> 0.35.1", only: :dev, runtime: false},
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_test, "~> 0.5", runtime: false},
      {:plug_cowboy, "~> 2.7", only: :test, runtime: false},
      {:phoenix_ecto, "~> 4.5", optional: true},
      {:ecto_sql, "~> 3.10", optional: true}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      licenses: ["MIT"],
      links: %{"Github" => @source_url},
      exclude_patterns: ~w(assets/node_modules priv/static/assets)
    ]
  end

  defp docs do
    [
      main: "PhoenixTest.Playwright"
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": ["esbuild.install --if-missing"],
      "assets.build": ["esbuild default"]
    ]
  end
end
