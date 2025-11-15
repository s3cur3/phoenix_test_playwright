defmodule PhoenixTest.PlaywrightTest do
  @moduledoc """
  Tests for non-phoenix_test-standard behaviour.
  Standard behaviour should instead be covered by `./upstream` tests.
  """

  use PhoenixTest.Playwright.Case, async: true

  import ExUnit.CaptureLog, only: [capture_log: 1]

  alias ExUnit.AssertionError
  alias PhoenixTest.Playwright
  alias PhoenixTest.Playwright.Selector

  describe "screenshot/3" do
    test "takes a screenshot of the current page as a PNG", %{conn: conn} do
      name = "png_#{:erlang.system_time(:second)}.png"

      conn
      |> visit("/pw/live/index")
      |> assert_has("h1", text: "LiveView main page")
      |> screenshot(name, full_page: false, omit_background: true)

      assert File.exists?("screenshots/#{name}")
    end

    test "takes a screenshot of the current page as a JPEG", %{conn: conn} do
      name = "jpg_#{:erlang.system_time(:second)}.jpg"

      conn
      |> visit("/pw/live/index")
      |> assert_has("h1", text: "LiveView main page")
      |> screenshot(name)

      assert File.exists?("screenshots/#{name}")
    end

    test "full page screenshots are larger in file size than non-full-page", %{conn: conn} do
      full_page_name = "full_page_#{:erlang.system_time(:second)}.png"
      viewport_name = "viewport_#{:erlang.system_time(:second)}.png"

      conn
      |> visit("/pw/live/index")
      |> assert_has("h1", text: "LiveView main page")
      |> screenshot(full_page_name, full_page: true)
      |> screenshot(viewport_name, full_page: false)

      assert {:ok, %File.Stat{size: full_page_size}} = File.stat("screenshots/#{full_page_name}")
      assert {:ok, %File.Stat{size: viewport_size}} = File.stat("screenshots/#{viewport_name}")

      assert full_page_size > viewport_size
    end
  end

  describe "browser dialog handling: accept_dialogs config and with_dialog/3" do
    test "accepts dialog by default", %{conn: conn} do
      conn
      |> visit("/pw/live/index")
      |> click_link("Confirm to navigate")
      |> assert_path("/pw/live/page_2")
    end

    @tag accept_dialogs: false
    test "override config via tag: dismisses dialog and fails click_link", %{conn: conn} do
      assert_raise AssertionError, fn ->
        conn
        |> visit("/pw/live/index")
        |> click_link("Confirm to navigate")
      end
    end

    @tag accept_dialogs: false
    test "with_dialog/3 accepts dialog conditionally", %{conn: conn} do
      conn
      |> visit("/pw/live/index")
      |> with_dialog(
        fn %{message: "Are you sure?"} -> :accept end,
        fn conn ->
          conn
          |> click_link("Confirm to navigate")
          |> assert_path("/pw/live/page_2")
        end
      )
    end
  end

  describe "open_browser" do
    setup do
      open_fun = fn path ->
        html = path |> File.read!() |> LazyHTML.from_document()
        [css_href] = html |> LazyHTML.query("link[rel=stylesheet]") |> LazyHTML.attribute("href")
        assert css_href =~ "phoenix_test_playwright\/priv\/static\/assets\/app\.css"

        path
      end

      %{open_fun: open_fun}
    end

    test "opens the browser ", %{conn: conn, open_fun: open_fun} do
      conn
      |> visit("/pw/page/index")
      |> open_browser(open_fun)
      |> assert_has("h1", text: "Main page")
    end
  end

  describe "unwrap" do
    test "provides an escape hatch that gives access to the underlying frame", %{conn: conn} do
      conn
      |> visit("/pw/live/index")
      |> unwrap(fn %{frame_id: frame_id} ->
        selector = Selector.role("link", "Navigate link")
        {:ok, _} = Playwright.Frame.click(frame_id, selector)
      end)
      |> assert_has("h1", text: "LiveView page 2")
    end
  end

  describe "type/3" do
    test "fills in a single text field based on the label", %{conn: conn} do
      conn
      |> visit("/pw/live/index")
      |> type("#email", "someone@example.com")
      |> assert_has("#form-data", text: "email: someone@example.com")
    end
  end

  describe "press/3" do
    test "submits a form via Enter key", %{conn: conn} do
      conn
      |> visit("/pw/live/index")
      |> type("#redirect-form-name", "name")
      |> press("#redirect-form-name", "Enter")
      |> assert_path("/pw/live/page_2")
    end
  end

  describe "drag/3" do
    test "triggers a javascript event handler", %{conn: conn} do
      conn
      |> visit("/pw/live/index")
      |> refute_has("#drag-status", text: "dropped")
      |> drag(Selector.text("Drag this"), to: Selector.text("Drop here"))
      |> assert_has("#drag-status", text: "dropped")
    end
  end

  describe "add_cookies/2" do
    test "sets a plain cookie", %{conn: conn} do
      conn
      |> add_cookies([[name: "name", value: "42"]])
      |> visit("/pw/page/cookies")
      |> assert_has("#form-data", text: "name: 42")
    end

    test "sets an encrypted cookie", %{conn: conn} do
      conn
      |> add_cookies([[name: "name", value: "42", encrypt: true]])
      |> visit("/pw/page/cookies?encrypted[]=")
      |> assert_has("#form-data", text: "name:")
      |> refute_has("#form-data", text: "name: 42")

      conn
      |> add_cookies([[name: "name", value: "42", encrypt: true]])
      |> visit("/pw/page/cookies?encrypted[]=name")
      |> assert_has("#form-data", text: "name: 42")
    end

    test "sets a signed cookie", %{conn: conn} do
      conn
      |> add_cookies([[name: "name", value: "42", sign: true]])
      |> visit("/pw/page/cookies?signed[]=")
      |> assert_has("#form-data", text: "name:")
      |> refute_has("#form-data", text: "name: 42")

      conn
      |> add_cookies([[name: "name", value: "42", sign: true]])
      |> visit("/pw/page/cookies?signed[]=name")
      |> assert_has("#form-data", text: "name: 42")
    end
  end

  describe "add_session_cookie/3" do
    test "puts a signed, encrypted cookie on the Conn", %{conn: conn} do
      cookie = [value: %{secret: "monty_python"}]

      conn
      |> add_session_cookie(cookie, PhoenixTest.Endpoint.session_options())
      |> visit("/pw/page/session")
      |> assert_has("#form-data", text: "secret: monty_python")
    end
  end

  describe "clear_cookies/2" do
    test "removes all cookies", %{conn: conn} do
      conn
      |> add_cookies([[name: "name", value: "42"]])
      |> visit("/pw/page/cookies")
      |> assert_has("#form-data", text: "name: 42")
      |> clear_cookies()
      |> visit("/pw/page/cookies")
      |> refute_has("#form-data", text: "name: 42")
    end
  end

  describe "javascript logs" do
    test "logs file and line number", %{conn: conn} do
      log =
        capture_log(fn ->
          visit(conn, "/pw/page/js_script_console_error")
        end)

      assert log =~ "TESTME 42 (http://localhost:4002/pw/page/js_script_console_error:16)"
    end

    test "logs without location if unknown", %{conn: conn} do
      log =
        capture_log(fn ->
          conn
          |> visit("/pw/live/index")
          |> tap(&PhoenixTest.Playwright.Frame.evaluate(&1.frame_id, "console.error('TESTME 42')"))
        end)

      assert log =~ "TESTME 42\n"
    end
  end
end
