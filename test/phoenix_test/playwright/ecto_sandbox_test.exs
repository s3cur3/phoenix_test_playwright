defmodule PhoenixTest.Playwright.EctoSandboxTest do
  use PhoenixTest.Playwright.Case, async: true

  for delay_ms <- [0, 100] do
    @delay_ms delay_ms
    describe "delay: #{delay_ms}ms" do
      setup %{conn: conn} do
        [conn: visit(conn, "/pw/live/ecto?delay_ms=#{@delay_ms}")]
      end

      test "shows version", %{conn: conn} do
        assert_has(conn, "div", text: "Version: PostgreSQL")
      end

      test "shows long running query result", %{conn: conn} do
        assert_has(conn, "div", text: "Long running: void")
      end

      test "shows delayed version", %{conn: conn} do
        assert_has(conn, "div", text: "Delayed version: PostgreSQL")
      end
    end
  end
end
