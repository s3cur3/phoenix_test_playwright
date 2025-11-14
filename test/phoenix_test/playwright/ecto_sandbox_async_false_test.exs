defmodule PhoenixTest.Playwright.EctoSandboxAsyncFalseTest do
  use PhoenixTest.Playwright.Case, async: false

  for delay_ms <- [0, 100] do
    @delay_ms delay_ms

    describe "delay: #{delay_ms}ms requires ecto_sandbox_stop_owner_delay to prevent 'is still using a connection from owner' errors" do
      @describetag ecto_sandbox_stop_owner_delay: delay_ms + 100

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
