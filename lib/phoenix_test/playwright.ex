defmodule PhoenixTest.Playwright do
  @moduledoc ~S"""
  > #### Warning {: .warning}
  >
  > This driver is experimental.
  > If you don't need browser based tests, see `m:PhoenixTest#module-usage` on regular usage.

  Execute PhoenixTest cases in an actual browser via [Playwright](https://playwright.dev/).

  ## Example
  Refer to the accompanying example repo for a full example:
  https://github.com/ftes/phoenix_test_playwright_example/commits/main

  ## Setup
  1. Add to `mix.exs` deps: `{:phoenix_test_playwright, "~> 0.1", only: :test, runtime: false}`
  2. Install Playwright: `npm --prefix assets i -D playwright`
  3. Install browsers: `npm --prefix assets exec playwright install --with-deps`
  4. Add to `config/test.exs`: `config :phoenix_test, otp_app: :your_app, playwright: [cli: "assets/node_modules/playwright/cli.js"]` (for more options, see [Configuration](#module-configuration) below)
  5. Add to `config/test.exs`: `config :your_app, YourAppWeb.Endpoint, server: true`
  6. Add to `test/test_helpers.exs`: `Application.put_env(:phoenix_test, :base_url, YourAppWeb.Endpoint.url())`

  ## Usage
  ```elixir
  defmodule MyFeatureTest do
    use PhoenixTest.Case, async: true
    @moduletag :playwright

    @tag trace: :open
    test "heading", %{conn: conn} do
      conn
      |> visit("/")
      |> assert_has("h1", text: "Heading")
    end
  end
  ```

  As shown above, you can use `m:ExUnit.Case#module-parameterized-tests` parameterized tests
  to run tests concurrently in different browsers.

  ## Configuration
  In `config/runtime.test.exs`:

  ```elixir
  config :phoenix_test,
    otp_app: :your_app,
    playwright: [
      cli: "assets/node_modules/playwright/cli.js",
      browser: [browser: :chromium, headless: System.get_env("PLAYWRIGHT_HEADLESS", "t") in ~w(t true)],
      trace: System.get_env("PLAYWRIGHT_TRACE", "false") in ~w(t true),
      trace_dir: "tmp",
      js_logger:
        # Default to true if you like seeing log messages for errors during test
        if System.get_env("PLAYWRIGHT_LOG_JS_MESSSAGES", "false") in ~w(t true) do
          :default
        else
          nil
        end
    ],
    timeout_ms: 2000
  ```

  JavaScript console messages are are written to standard IO and standard error by default.
  You can set the `:js_logger` config to `nil` to silence them.

  ## Playwright Traces
  You can enable [trace](https://playwright.dev/docs/trace-viewer-intro) recording in different ways:
  - Environment variable, see [Configuration](#module-configuration)
  - ExUnit `@tag :trace`
  - ExUnit `@tag trace: :open` to open the trace viewer automatically after completion

  ## Common problems
  - Test failures in CI (timeouts): Try less concurrency, e.g. `mix test --max-cases 1` for GitHub CI shared runners
  - LiveView not connected: add `assert_has("body .phx-connected")` to test after `visit`ing (or otherwise navigating to) a LiveView
  - LiveComponent not connected: add `data-connected={connected?(@socket)}` to template and `assert_has("#my-component[data-connected]")` to test

  ## Ecto SQL.Sandbox
  `PhoenixTest.Case` automatically takes care of this.
  It passes a user agent referencing your Ecto repos.
  This allows for [concurrent browser tests](https://hexdocs.pm/phoenix_ecto/main.html#concurrent-browser-tests).

  Make sure to follow the advanced set up instructions if necessary:
  - [with LiveViews](https://hexdocs.pm/phoenix_ecto/Phoenix.Ecto.SQL.Sandbox.html#module-acceptance-tests-with-liveviews)
  - [with Channels](https://hexdocs.pm/phoenix_ecto/Phoenix.Ecto.SQL.Sandbox.html#module-acceptance-tests-with-channels)

  ```elixir
  defmodule MyTest do
    use PhoenixTest.Case, async: true
  ```

  ## Advanced assertions
  ```elixir
  def assert_has_value(session, label, value, opts \\ []) do
    opts = Keyword.validate!(opts, exact: true)

    assert_found(session,
      selector: Selector.label(label, opts),
      expression: "to.have.value",
      expectedText: [%{string: value}]
    )
  end

  def assert_has_selected(session, label, value, opts \\ []) do
    opts = Keyword.validate!(opts, exact: true)

    assert_found(session,
      selector: label |> Selector.label(opts) |> Selector.concat("option[selected]"),
      expression: "to.have.text",
      expectedText: [%{string: value}]
    )
  end

  def assert_is_chosen(session, label, opts \\ []) do
    opts = Keyword.validate!(opts, exact: true)

    assert_found(session,
      selector: Selector.label(label, opts),
      expression: "to.have.attribute",
      expressionArg: "checked"
    )
  end

  def assert_is_editable(session, label, opts \\ []) do
    opts = Keyword.validate!(opts, exact: true)

    assert_found(session,
      selector: Selector.label(label, opts),
      expression: "to.be.editable"
    )
  end

  def refute_is_editable(session, label, opts \\ []) do
    opts = Keyword.validate!(opts, exact: true)

    assert_found(
      session,
      [
        selector: Selector.label(label, opts),
        expression: "to.be.editable"
      ],
      is_not: true
    )
  end

  def assert_found(session, params, opts \\ []) do
    is_not = Keyword.get(opts, :is_not, false)
    params = Enum.into(params, %{isNot: is_not})

    unwrap(session, fn frame_id ->
      {:ok, found} = Frame.expect(frame_id, params)
      if is_not, do: refute(found), else: assert(found)
    end)
  end

  def assert_download(session, name, contains: content) do
    assert_receive({:playwright, %{method: "download"} = download_msg}, 2000)
    artifact_guid = download_msg.params.artifact.guid
    assert_receive({:playwright, %{method: "__create__", params: %{guid: ^artifact_guid}} = artifact_msg}, 2000)
    download_path = artifact_msg.params.initializer.absolutePath
    wait_for_file(download_path)

    assert download_msg.params.suggestedFilename =~ name
    assert File.read!(download_path) =~ content

    session
  end

  defp wait_for_file(path, remaining_ms \\ 2000, wait_for_ms \\ 100)
  defp wait_for_file(path, remaining_ms, _) when remaining_ms <= 0, do: flunk("File #{path} does not exist")

  defp wait_for_file(path, remaining_ms, wait_for_ms) do
    if File.exists?(path) do
      :ok
    else
      Process.sleep(wait_for_ms)
      wait_for_file(path, remaining_ms - wait_for_ms, wait_for_ms)
    end
  end
  ```
  """

  import ExUnit.Assertions

  alias PhoenixTest.OpenBrowser
  alias PhoenixTest.Playwright.Connection
  alias PhoenixTest.Playwright.Frame
  alias PhoenixTest.Playwright.Selector

  require Logger

  defstruct [:context_id, :page_id, :frame_id, :last_input_selector, within: :none]

  @endpoint Application.compile_env(:phoenix_test, :endpoint)
  @default_timeout_ms 1000

  def build(context_id, page_id, frame_id) do
    %__MODULE__{context_id: context_id, page_id: page_id, frame_id: frame_id}
  end

  def retry(fun, backoff_ms \\ [100, 250, 500, timeout()])
  def retry(fun, []), do: fun.()

  def retry(fun, [sleep_ms | backoff_ms]) do
    fun.()
  rescue
    ExUnit.AssertionError ->
      Process.sleep(sleep_ms)
      retry(fun, backoff_ms)
  end

  def visit(session, path) do
    url =
      case path do
        "http://" <> _ -> path
        "https://" <> _ -> path
        _ -> Application.fetch_env!(:phoenix_test, :base_url) <> path
      end

    Frame.goto(session.frame_id, url)
    session
  end

  def assert_has(session, "title") do
    retry(fn -> assert render_page_title(session) != nil end)
  end

  def assert_has(session, selector), do: assert_has(session, selector, [])

  def assert_has(session, "title", opts) do
    text = Keyword.fetch!(opts, :text)
    exact = Keyword.get(opts, :exact, false)

    if exact do
      retry(fn -> assert render_page_title(session) == text end)
    else
      retry(fn -> assert render_page_title(session) =~ text end)
    end

    session
  end

  def assert_has(session, selector, opts) do
    if !found?(session, selector, opts) do
      flunk("Could not find element #{selector} #{inspect(opts)}")
    end

    session
  end

  def refute_has(session, "title") do
    retry(fn -> assert render_page_title(session) == nil end)
  end

  def refute_has(session, selector), do: refute_has(session, selector, [])

  def refute_has(session, "title", opts) do
    text = Keyword.fetch!(opts, :text)
    exact = Keyword.get(opts, :exact, false)

    if exact do
      retry(fn -> refute render_page_title(session) == text end)
    else
      retry(fn -> refute render_page_title(session) =~ text end)
    end

    session
  end

  def refute_has(session, selector, opts) do
    if found?(session, selector, opts) do
      flunk("Found element #{selector} #{inspect(opts)}")
    end

    session
  end

  defp found?(session, selector, opts) do
    selector =
      session
      |> maybe_within()
      |> Selector.concat(Selector.css(selector))
      |> Selector.concat("visible=true")
      |> Selector.concat(Selector.text(opts[:text], opts))

    if opts[:count] do
      if opts[:at],
        do: raise(ArgumentError, message: "Options `count` and `at` can not be used together.")

      params =
        %{
          expression: "to.have.count",
          expectedNumber: opts[:count],
          selector: Selector.build(selector),
          timeout: timeout(opts)
        }

      {:ok, found?} = Frame.expect(session.frame_id, params)
      found?
    else
      params =
        %{
          selector: selector |> Selector.concat(Selector.at(opts[:at])) |> Selector.build(),
          timeout: timeout(opts)
        }

      case Frame.wait_for_selector(session.frame_id, params) do
        {:ok, _} -> true
        _ -> false
      end
    end
  end

  def render_page_title(session) do
    case Frame.title(session.frame_id) do
      {:ok, ""} -> nil
      {:ok, title} -> title
    end
  end

  def render_html(session) do
    selector = session |> maybe_within() |> Selector.build()
    {:ok, html} = Frame.inner_html(session.frame_id, selector)
    html
  end

  def click(session, selector) do
    session.frame_id
    |> Frame.click(selector)
    |> handle_response()

    session
  end

  def click(session, selector, text, opts \\ []) do
    opts = Keyword.validate!(opts, exact: false)

    selector =
      session
      |> maybe_within()
      |> Selector.concat(selector)
      |> Selector.concat(Selector.text(text, opts))

    session.frame_id
    |> Frame.click(selector)
    |> handle_response()

    session
  end

  def click_link(session, selector \\ nil, text, opts \\ []) do
    opts = Keyword.validate!(opts, exact: false)

    selector =
      session
      |> maybe_within()
      |> Selector.concat(
        case selector do
          nil -> Selector.link(text, opts)
          css -> css |> Selector.css() |> Selector.concat(Selector.text(text, opts))
        end
      )
      |> Selector.build()

    session.frame_id
    |> Frame.click(selector)
    |> handle_response()

    session
  end

  def click_button(session, selector \\ nil, text, opts \\ []) do
    opts = Keyword.validate!(opts, exact: false)

    selector =
      session
      |> maybe_within()
      |> Selector.concat(
        case selector do
          nil -> Selector.button(text, opts)
          css -> css |> Selector.css() |> Selector.concat(Selector.text(text, opts))
        end
      )
      |> Selector.build()

    session.frame_id
    |> Frame.click(selector)
    |> handle_response()

    session
  end

  def within(session, selector, fun) do
    session
    |> Map.put(:within, selector)
    |> fun.()
    |> Map.put(:within, :none)
  end

  def fill_in(session, css_selector \\ nil, label, opts) do
    {value, opts} = Keyword.pop!(opts, :with)
    fun = &Frame.fill(session.frame_id, &1, to_string(value), &2)
    input(session, css_selector, label, opts, fun)
  end

  def select(session, css_selector \\ nil, option_labels, opts) do
    if opts[:exact_option] != true, do: raise("exact_option not implemented")

    {label, opts} = Keyword.pop!(opts, :from)
    options = option_labels |> List.wrap() |> Enum.map(&%{label: &1})
    fun = &Frame.select_option(session.frame_id, &1, options, &2)
    input(session, css_selector, label, opts, fun)
  end

  def check(session, css_selector \\ nil, label, opts) do
    fun = &Frame.check(session.frame_id, &1, &2)
    input(session, css_selector, label, opts, fun)
  end

  def uncheck(session, css_selector \\ nil, label, opts) do
    fun = &Frame.uncheck(session.frame_id, &1, &2)
    input(session, css_selector, label, opts, fun)
  end

  def choose(session, css_selector \\ nil, label, opts) do
    fun = &Frame.check(session.frame_id, &1, &2)
    input(session, css_selector, label, opts, fun)
  end

  def upload(session, css_selector \\ nil, label, paths, opts) do
    paths = paths |> List.wrap() |> Enum.map(&Path.expand/1)
    fun = &Frame.set_input_files(session.frame_id, &1, paths, &2)
    input(session, css_selector, label, opts, fun)
  end

  defp input(session, css_selector, label, opts, fun) do
    selector =
      session
      |> maybe_within()
      |> Selector.concat(
        case css_selector do
          nil -> Selector.label(label, opts)
          css -> css |> Selector.css() |> Selector.and(Selector.label(label, opts))
        end
      )
      |> Selector.build()

    selector
    |> fun.(%{timeout: timeout(opts)})
    |> handle_response()

    %{session | last_input_selector: selector}
  end

  defp maybe_within(session) do
    case session.within do
      :none -> Selector.none()
      selector -> selector
    end
  end

  defp handle_response(result) do
    case result do
      {:error, %{error: %{error: %{name: "TimeoutError"}}} = error} ->
        flunk("Could not find element:\n#{inspect(error)}")

      {:error,
       %{error: %{error: %{name: "Error", message: "Error: strict mode violation" <> _}}} = error} ->
        flunk("Found more than one element:\n#{inspect(error)}")

      {:error,
       %{
         error: %{
           error: %{name: "Error", message: "Clicking the checkbox did not change its state"}
         }
       }} ->
        :ok

      {:ok, result} ->
        result
    end
  end

  def submit(session) do
    Frame.press(session.frame_id, session.last_input_selector, "Enter")
    session
  end

  def open_browser(session, open_fun \\ &OpenBrowser.open_with_system_cmd/1) do
    # Await any pending navigation
    Process.sleep(100)
    {:ok, html} = Frame.content(session.frame_id)

    fixed_html =
      html
      |> Floki.parse_document!()
      |> Floki.traverse_and_update(&OpenBrowser.prefix_static_paths(&1, @endpoint))
      |> Floki.raw_html()

    path = Path.join([System.tmp_dir!(), "phx-test#{System.unique_integer([:monotonic])}.html"])
    File.write!(path, fixed_html)
    open_fun.(path)

    session
  end

  def unwrap(session, fun) do
    fun.(Map.take(session, ~w(context_id page_id frame_id)a))
    session
  end

  def current_path(session) do
    resp =
      session.frame_id
      |> Connection.received()
      |> Enum.find(&match?(%{method: "navigated", params: %{url: _}}, &1))

    if resp == nil, do: raise(ArgumentError, "Could not find current path.")

    uri = URI.parse(resp.params.url)
    [uri.path, uri.query] |> Enum.reject(&is_nil/1) |> Enum.join("?")
  end

  defp timeout(opts \\ []) do
    default = Application.get_env(:phoenix_test, :timeout_ms, @default_timeout_ms)
    Keyword.get(opts, :timeout, default)
  end
end

defimpl PhoenixTest.Driver, for: PhoenixTest.Playwright do
  alias PhoenixTest.Assertions
  alias PhoenixTest.Playwright

  defdelegate visit(session, path), to: Playwright
  defdelegate render_page_title(session), to: Playwright
  defdelegate render_html(session), to: Playwright
  defdelegate within(session, selector, fun), to: Playwright
  defdelegate click_link(session, text), to: Playwright
  defdelegate click_link(session, selector, text), to: Playwright
  defdelegate click_button(session, text), to: Playwright
  defdelegate click_button(session, selector, text), to: Playwright
  defdelegate fill_in(session, label, opts), to: Playwright
  defdelegate fill_in(session, selector, label, opts), to: Playwright
  defdelegate select(session, selector, option, opts), to: Playwright
  defdelegate select(session, option, opts), to: Playwright
  defdelegate check(session, selector, label, opts), to: Playwright
  defdelegate check(session, label, opts), to: Playwright
  defdelegate uncheck(session, selector, label, opts), to: Playwright
  defdelegate uncheck(session, label, opts), to: Playwright
  defdelegate choose(session, selector, label, opts), to: Playwright
  defdelegate choose(session, label, opts), to: Playwright
  defdelegate upload(session, selector, label, path, opts), to: Playwright
  defdelegate upload(session, label, path, opts), to: Playwright
  defdelegate submit(session), to: Playwright
  defdelegate open_browser(session), to: Playwright
  defdelegate open_browser(session, open_fun), to: Playwright
  defdelegate unwrap(session, fun), to: Playwright
  defdelegate current_path(session), to: Playwright

  defdelegate assert_has(session, selector), to: Playwright
  defdelegate assert_has(session, selector, opts), to: Playwright
  defdelegate refute_has(session, selector), to: Playwright
  defdelegate refute_has(session, selector, opts), to: Playwright

  def assert_path(session, path),
    do: Playwright.retry(fn -> Assertions.assert_path(session, path) end)

  def assert_path(session, path, opts),
    do: Playwright.retry(fn -> Assertions.assert_path(session, path, opts) end)

  def refute_path(session, path),
    do: Playwright.retry(fn -> Assertions.refute_path(session, path) end)

  def refute_path(session, path, opts),
    do: Playwright.retry(fn -> Assertions.refute_path(session, path, opts) end)
end
