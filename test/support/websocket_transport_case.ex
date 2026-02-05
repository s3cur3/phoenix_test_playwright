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

    # Update base_url so container can reach the host
    # - macOS/Windows Docker Desktop: use host.docker.internal
    # - Linux: use the Docker bridge gateway IP (typically 172.17.0.1)
    current_base_url = Application.get_env(:phoenix_test, :base_url)
    docker_host = docker_host_address()

    container_accessible_base_url =
      current_base_url
      |> URI.parse()
      |> Map.put(:host, docker_host)
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

  # Returns the hostname/IP that Docker containers can use to reach the host machine
  defp docker_host_address do
    case :os.type() do
      {:unix, :darwin} ->
        # macOS Docker Desktop supports host.docker.internal
        "host.docker.internal"

      {:unix, :linux} ->
        # Linux: get the Docker bridge gateway IP
        case System.cmd("docker", [
               "network",
               "inspect",
               "bridge",
               "--format",
               "{{range .IPAM.Config}}{{.Gateway}}{{end}}"
             ]) do
          {gateway, 0} -> String.trim(gateway)
          _ -> "172.17.0.1"
        end

      {:win32, _} ->
        # Windows Docker Desktop supports host.docker.internal
        "host.docker.internal"

      _ ->
        # Fallback
        "host.docker.internal"
    end
  end
end
