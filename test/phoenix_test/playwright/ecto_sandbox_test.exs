defmodule PhoenixTest.Playwright.EctoSandboxTest do
  use PhoenixTest.Playwright.Case, async: true

  test "visits page", %{conn: conn} do
    conn
    |> visit("/pw/live/ecto")
    |> assert_has("h1", text: "PostgreSQL")
  end
end
