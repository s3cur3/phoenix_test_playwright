defmodule PhoenixTest.Playwright.ConnectionDefaultTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Playwright.Connection

  test "launch_browser/2 produces a reasonable error on timeout" do
    for opts <- [
          %{browser_launch_timeout: -1_000},
          # :browser_launch_timeout overrides :timeout for this particular use case
          %{browser_launch_timeout: -1_000, timeout: 10_000},
          # :timeout is used as fallback if :browser_launch_timeout is not set
          %{timeout: -1_000}
        ] do
      try do
        Connection.launch_browser(:chromium, opts)
        flunk("Launch browser should have raised a timeout error")
      rescue
        error in RuntimeError ->
          assert error.message =~ "Timed out while launching the Playwright browser, Chromium."
          assert error.message =~ "You may need to increase the :browser_launch_timeout"
      end
    end
  end
end
