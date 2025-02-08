screenshot_opts_schema = [
  full_page: [type: :boolean, default: true],
  omit_background: [type: :boolean, default: false]
]

trace_opts_schema = [
  open: [type: :boolean, default: false]
]

browsers = ~w(android chromium electron firefox webkit)a

schema =
  NimbleOptions.new!(
    browser: [
      default: :chromium,
      type: {:in, browsers},
      type_doc: "`#{Enum.map_join(browsers, " | ", &":#{&1}")}`",
      doc: "Override via `Case` opts or `parameterize`."
    ],
    cli: [
      default: "assets/node_modules/playwright/cli.js",
      type: :string
    ],
    headless: [
      default: true,
      doc: "Override via `Case` opts.",
      type: :boolean
    ],
    js_logger: [
      default: :default,
      type: {:or, [{:in, [:default, false]}, {:fun, 1}]},
      type_doc: "`:default | false | (msg -> nil)`"
    ],
    screenshot: [
      default: false,
      type: {:or, [:boolean, non_empty_keyword_list: screenshot_opts_schema]},
      type_doc: "`boolean() | Keyword.t()`",
      doc: "Override via `@tag`.\n\n" <> NimbleOptions.docs(screenshot_opts_schema, nest_level: 1)
    ],
    screenshot_dir: [
      default: "screenshots",
      type: :string
    ],
    timeout: [
      default: :timer.seconds(2),
      type: :non_neg_integer
    ],
    slow_mo: [
      default: :timer.seconds(0),
      type: :non_neg_integer,
      doc: "Override via `Case` opts."
    ],
    trace: [
      default: false,
      type: {:or, [:boolean, {:in, [:open]}, non_empty_keyword_list: trace_opts_schema]},
      type_doc: "`boolean() | :open | Keyword.t()`",
      doc: "Override via `@tag`.\n\n" <> NimbleOptions.docs(trace_opts_schema, nest_level: 1)
    ],
    trace_dir: [
      default: "traces",
      type: :string
    ]
  )

defmodule PhoenixTest.Playwright.Config do
  @moduledoc """
  Configuration options for the Playwright driver.
  Most configuration is global (`config/test.exs`).
  Some configuration can be overridden via ExUnit tags.

  #{NimbleOptions.docs(schema)}
  """

  @schema schema
  @screenshot_opts_schema screenshot_opts_schema
  @trace_opts_schema trace_opts_schema

  def validate!(config) when is_map(config), do: config |> Keyword.new() |> validate!()

  def validate!(config) when is_list(config) do
    global()
    |> Keyword.merge(config)
    |> NimbleOptions.validate!(@schema)
    |> normalize()
  end

  def global do
    :phoenix_test
    |> Application.get_env(:playwright, [])
    |> NimbleOptions.validate!(@schema)
    |> normalize()
  end

  def global(key), do: Keyword.fetch!(global(), key)

  defp normalize(config), do: Keyword.new(config, fn {key, value} -> {key, normalize(key, value)} end)
  defp normalize(:screenshot, true), do: NimbleOptions.validate!([], @screenshot_opts_schema)
  defp normalize(:trace, :open), do: NimbleOptions.validate([open: true], @trace_opts_schema)
  defp normalize(:trace, true), do: NimbleOptions.validate!([], @trace_opts_schema)
  defp normalize(_key, value), do: value
end
