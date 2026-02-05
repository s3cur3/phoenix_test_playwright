defmodule PhoenixTest.Playwright.WebsocketTransportTest do
  @moduledoc """
  Tests that verify WebSocket transport works correctly with PhoenixTest.Playwright.

  These tests use a Playwright Docker container started via testcontainers.
  """

  use WebsocketTransportCase, async: false

  describe "websocket transport" do
    test "can visit local pages and make assertions", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("h1", text: "LiveView main page")
    end

    test "can interact with page elements", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_link("Navigate link")
      |> assert_has("h1", text: "LiveView page 2")
    end
  end
end
