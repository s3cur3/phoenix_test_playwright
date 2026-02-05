alias PhoenixTest.Endpoint

websocket_only? = System.get_env("WEBSOCKET_TESTS") == "true"

ExUnit.start(
  capture_log: false,
  exclude: if(websocket_only?, do: [:test], else: [:websocket]),
  include: if(websocket_only?, do: [:websocket], else: [])
)

{:ok, _} = PhoenixTest.Playwright.Repo.start_link()
{:ok, _} = Supervisor.start_link([{Phoenix.PubSub, name: PhoenixTest.PubSub}], strategy: :one_for_one)
{:ok, _} = Endpoint.start_link()

# Skip starting the default supervisor for websocket tests - they start their own
if not websocket_only? do
  {:ok, _} = PhoenixTest.Playwright.Supervisor.start_link()
end

Application.put_env(:phoenix_test, :base_url, Endpoint.url())
