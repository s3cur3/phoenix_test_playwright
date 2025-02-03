defmodule PhoenixTest.Playwright.Config do
  @moduledoc """
  Configuration options for the Playwright driver.
  Most configuration is global (`config/test.exs`).
  Some configuration can be overridden via ExUnit tags (`@moduletag` etc.).

  Check source code to see what can be overriden.
  """

  @default [
    # override via @moduletag
    browser: :chromium,

    # global only
    cli: "assets/node_modules/playwright/cli.js",

    # override via @moduletag
    headless: true,

    # global only
    # values: false, :default, fn msg -> _ end, {Module, :function}
    js_logger: :default,

    # override via @tag
    # valuestrue, [full_page: true, omit_background: true]
    screenshot: false,

    # global only
    screenshot_dir: "screenshots",

    # global only
    timeout: :timer.seconds(2),

    # override via @moduletag
    slow_mo: :timer.seconds(0),

    # override via @moduletag
    # values: true, :open, [open: true]
    trace: false,

    # global only
    trace_dir: "traces"
  ]

  def parse(config) when is_map(config), do: config |> Keyword.new() |> parse()
  def parse(config) when is_list(config), do: Keyword.validate!(config, global())

  def global, do: :phoenix_test |> Application.get_env(:playwright, []) |> Keyword.validate!(@default)
  def global(key), do: Keyword.fetch!(global(), key)

  def keys, do: Keyword.keys(@default)
end
