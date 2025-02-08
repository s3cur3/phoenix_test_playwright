defmodule PhoenixTest.Playwright.CaseTest do
  use PhoenixTest.Playwright.Case, async: true

  describe "@tag :screenshot" do
    @tag :screenshot
    test "saves screenshot on test exit (for verification in CI)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("h1")
    end
  end

  describe "@tag :trace" do
    @tag :trace
    test "saves trace on test exit (for verification in CI)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("h1")
    end
  end
end
