import Config

config :logger, level: :error

config :phoenix_test_playwright, PhoenixTest.Endpoint,
  server: true,
  http: [port: 4000],
  live_view: [signing_salt: "112345678212345678312345678412"],
  secret_key_base: String.duplicate("57689", 50),
  pubsub_server: PhoenixTest.PubSub

config :phoenix_test,
  endpoint: PhoenixTest.Endpoint,
  otp_app: :phoenix_test_playwright,
  playwright: [
    cli: "priv/static/assets/node_modules/playwright/cli.js",
    browser: [
      browser: :chromium,
      headless: System.get_env("PLAYWRIGHT_HEADLESS", "t") in ~w(t true)
    ],
    trace: System.get_env("PLAYWRIGHT_TRACE", "false") in ~w(t true),
    trace_dir: "tmp"
  ],
  timeout_ms: 2000

config :esbuild,
  version: "0.17.11",
  default: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../../priv/static/assets),
    cd: Path.expand("../test/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]
