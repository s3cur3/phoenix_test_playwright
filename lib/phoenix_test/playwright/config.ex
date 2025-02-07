screenshot_opts_schema = [
  full_page: [type: :boolean, default: true],
  omit_background: [type: :boolean, default: false]
]

trace_opts_schema = [
  open: [type: :boolean, default: false]
]

browsers = ~w(android chromium electron firefox webkit)a

schema = [
  browser: [
    default: :chromium,
    type: {:in, browsers},
    type_doc: "`#{Enum.map_join(browsers, " | ", &":#{&1}")}`",
    doc: "Override via `@moduletag` or `parameterize`."
  ],
  cli: [
    default: "assets/node_modules/playwright/cli.js",
    type: :string
  ],
  headless: [
    default: true,
    doc: "Override via `@moduletag`.",
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
    doc: "Override via `@moduletag`."
  ],
  trace: [
    default: false,
    type: {:or, [:boolean, non_empty_keyword_list: trace_opts_schema]},
    type_doc: "`boolean() | Keyword.t()`",
    doc: "Override via `@tag`.\n\n" <> NimbleOptions.docs(trace_opts_schema, nest_level: 1)
  ],
  trace_dir: [
    default: "traces",
    type: :string
  ]
]

compiled_schema = NimbleOptions.new!(schema)

defmodule PhoenixTest.Playwright.Config do
  @moduledoc """
  Configuration options for the Playwright driver.
  Most configuration is global (`config/test.exs`).
  Some configuration can be overridden via ExUnit tags.

  #{NimbleOptions.docs(compiled_schema)}
  """

  @schema schema
  @compiled_schema compiled_schema

  def validate!(config) when is_map(config), do: config |> Keyword.new() |> validate!()

  def validate!(config) when is_list(config),
    do: global() |> Keyword.merge(config) |> NimbleOptions.validate!(@compiled_schema)

  def global, do: :phoenix_test |> Application.get_env(:playwright, []) |> NimbleOptions.validate!(@compiled_schema)
  def global(key), do: Keyword.fetch!(global(), key)

  def keys, do: Keyword.keys(@schema)
end
