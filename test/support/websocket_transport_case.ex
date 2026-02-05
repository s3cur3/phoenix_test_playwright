defmodule WebsocketTransportCase do
  @moduledoc """
  Test case for tests that use WebSocket transport to connect to a remote Playwright server.

  Uses testcontainers to automatically start a Playwright Docker container.
  Starts `PhoenixTest.Playwright.Supervisor` with `ws_endpoint` config to use
  the containerized Playwright server.

  ## Usage

      defmodule MyWebsocketTest do
        use WebsocketTransportCase, async: false

        test "can visit pages", %{conn: conn} do
          conn
          |> visit("/page")
          |> assert_has("h1")
        end
      end

  Note: Tests using this case are excluded by default. Run them with:

      WEBSOCKET_TESTS=true mix test

  This skips starting the default Playwright supervisor and only runs websocket tests.
  """

  use ExUnit.CaseTemplate

  alias PhoenixTest.Playwright.Config

  @timeout 30_000

  using(opts) do
    quote do
      use PhoenixTest.Playwright.Case, [{:async, false} | unquote(opts)]

      @moduletag :websocket
    end
  end

  setup_all _context do
    # Get installed playwright version for matching Docker image
    {:ok, playwright_version} = Config.playwright_version()
    playwright_image = "mcr.microsoft.com/playwright:v#{playwright_version}-noble"

    # Start testcontainers
    {:ok, _} = Testcontainers.start_link()

    # Create and start the Playwright container
    container_config =
      playwright_image
      |> Testcontainers.Container.new()
      |> Testcontainers.Container.with_exposed_port(3000)
      |> Testcontainers.Container.with_cmd(
        ~w(npx -y playwright@#{playwright_version} run-server --port 3000 --host 0.0.0.0)
      )
      |> Testcontainers.Container.with_waiting_strategy(Testcontainers.PortWaitStrategy.new("localhost", 3000, 30_000))

    {:ok, container} = Testcontainers.start_container(container_config)

    # Get the mapped port and build ws_endpoint
    host_port = Testcontainers.Container.mapped_port(container, 3000)
    ws_endpoint = "ws://localhost:#{host_port}"

    # Update base_url to use host.docker.internal so container can reach the host
    # This works on macOS and Windows Docker Desktop
    current_base_url = Application.get_env(:phoenix_test, :base_url)

    container_accessible_base_url =
      current_base_url
      |> URI.parse()
      |> Map.put(:host, "host.docker.internal")
      |> URI.to_string()

    Application.put_env(:phoenix_test, :base_url, container_accessible_base_url)

    # Start supervisor with websocket config
    {:ok, _} =
      PhoenixTest.Playwright.Supervisor.start_link(
        ws_endpoint: ws_endpoint,
        timeout: @timeout,
        browser_pool: nil
      )

    on_exit(fn ->
      # Stop container
      try do
        Testcontainers.stop_container(container.container_id)
      catch
        :exit, _ -> :ok
      end
    end)

    [container: container, ws_endpoint: ws_endpoint]
  end
end
