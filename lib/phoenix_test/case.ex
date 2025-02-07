defmodule PhoenixTest.Case do
  @moduledoc """
  ExUnit case module to assist with browser based tests.
  See `PhoenixTest.Playwright` for more information.
  """

  use ExUnit.CaseTemplate

  alias PhoenixTest.Case
  alias PhoenixTest.Playwright
  alias PhoenixTest.Playwright.Config

  using _opts do
    quote do
      import PhoenixTest
      import PhoenixTest.Case
      import PhoenixTest.Playwright, only: [screenshot: 2, screenshot: 3]
    end
  end

  setup_all context do
    config = context |> Map.take(Config.keys()) |> Config.validate!()

    case context do
      %{playwright: true} ->
        browser_opts = Keyword.take(config, ~w(browser headless slow_mo)a)
        browser_id = Case.Playwright.launch_browser(browser_opts)
        Keyword.put(config, :browser_id, browser_id)

      %{playwright: p} when p != false ->
        raise ArgumentError, "Pass any playwright options as top-level tags, e.g. `@moduletag browser: :firefox`"

      _ ->
        :ok
    end
  end

  setup context do
    case context do
      %{playwright: true} ->
        [conn: Case.Playwright.new_session(context)]

      %{playwright: p} when p != false ->
        raise ArgumentError, "Pass any playwright options as top-level tags, e.g. `@tag :trace`"

      _ ->
        [conn: Phoenix.ConnTest.build_conn()]
    end
  end

  defmodule Playwright do
    @moduledoc false
    import PhoenixTest.Playwright.Connection

    alias PhoenixTest.Playwright.Browser
    alias PhoenixTest.Playwright.BrowserContext
    alias PhoenixTest.Playwright.Page
    alias PhoenixTest.Playwright.Port

    @includes_ecto Code.ensure_loaded?(Ecto.Adapters.SQL.Sandbox) &&
                     Code.ensure_loaded?(Phoenix.Ecto.SQL.Sandbox)

    def launch_browser(opts) do
      ensure_started()
      {browser, opts} = Keyword.pop!(opts, :browser)
      browser_id = launch_browser(browser, opts)
      on_exit(fn -> post(guid: browser_id, method: :close) end)
      browser_id
    end

    def new_session(context) do
      browser_context_opts = if ua = checkout_ecto_repos(context[:async]), do: %{user_agent: ua}, else: %{}
      browser_context_id = Browser.new_context(context.browser_id, browser_context_opts)
      subscribe(browser_context_id)

      page_id = BrowserContext.new_page(browser_context_id)
      Page.update_subscription(page_id, event: :console, enabled: true)

      frame_id = initializer(page_id).main_frame.guid
      on_exit(fn -> post(guid: browser_context_id, method: :close) end)

      if context.trace, do: trace(browser_context_id, context)
      if context.screenshot, do: screenshot(page_id, context)

      PhoenixTest.Playwright.build(browser_context_id, page_id, frame_id)
    end

    defp trace(browser_context_id, %{trace: opts, trace_dir: dir} = context) do
      opts =
        case opts do
          true -> []
          :open -> [open: true]
          list when is_list(list) -> opts
        end

      BrowserContext.start_tracing(browser_context_id)

      File.mkdir_p!(dir)
      file = file_name("_#{System.unique_integer([:positive, :monotonic])}.zip", context)
      path = Path.join(dir, file)

      on_exit(fn ->
        BrowserContext.stop_tracing(browser_context_id, path)

        if opts[:open] do
          cli_path = Path.join(File.cwd!(), Port.cli_path())
          System.cmd(cli_path, ["show-trace", path])
        end
      end)
    end

    defp screenshot(page_id, %{screenshot: opts} = context) do
      opts =
        case opts do
          true -> []
          list when is_list(list) -> opts
        end

      on_exit(fn ->
        file = file_name(".png", context)
        PhoenixTest.Playwright.screenshot(%{page_id: page_id}, file, opts)
      end)
    end

    defp file_name(suffix, %{module: module, test: test}) do
      "Elixir." <> module = to_string(module)
      time = :second |> :erlang.system_time() |> to_string()
      String.replace("#{module}.#{test}_#{time}#{suffix}", ~r/[^a-zA-Z0-9\.]/, "_")
    end

    if @includes_ecto do
      def checkout_ecto_repos(async?) do
        otp_app = Application.fetch_env!(:phoenix_test, :otp_app)
        repos = Application.get_env(otp_app, :ecto_repos, [])

        repos
        |> Enum.map(&checkout_ecto_repo(&1, async?))
        |> Phoenix.Ecto.SQL.Sandbox.metadata_for(self())
        |> Phoenix.Ecto.SQL.Sandbox.encode_metadata()
      end

      defp checkout_ecto_repo(repo, async?) do
        case Ecto.Adapters.SQL.Sandbox.checkout(repo) do
          :ok -> :ok
          {:already, :allowed} -> :ok
          {:already, :owner} -> :ok
        end

        if not async?, do: Ecto.Adapters.SQL.Sandbox.mode(repo, {:shared, self()})

        repo
      end
    else
      def checkout_ecto_repos(_) do
        nil
      end
    end
  end
end
