defmodule PhoenixTest.Playwright.Repo do
  use Ecto.Repo,
    otp_app: :phoenix_test_playwright,
    adapter: Ecto.Adapters.Postgres
end
