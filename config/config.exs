import Config

config :phoenix_test_playwright, PhoenixTest.Playwright.Repo,
  database: "phoenix_test_playwright_repo",
  username: "user",
  password: "pass",
  hostname: "localhost"

import_config "#{config_env()}.exs"
