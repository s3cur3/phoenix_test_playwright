defmodule PhoenixTest.Playwright.Config do
  @moduledoc false

  @default [
    browser: :chromium,
    cli: "assets/node_modules/playwright/cli.js",
    headless: true,
    js_logger: :default,

    # true, [full_page: true, omit_background: true]
    screenshot: false,
    screenshot_dir: "screenshots",
    timeout: :timer.seconds(2),
    slow_mo: 0,

    # true, :open, [open: true]
    trace: false,
    trace_dir: "traces"
  ]

  def parse(config) when is_map(config), do: config |> Keyword.new() |> parse()
  def parse(config) when is_list(config), do: Keyword.validate!(config, global())

  def global, do: :phoenix_test |> Application.get_env(:playwright, []) |> Keyword.validate!(@default)
  def global(key), do: Keyword.fetch!(global(), key)

  def keys, do: Keyword.keys(@default)
end
