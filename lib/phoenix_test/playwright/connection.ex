defmodule PhoenixTest.Playwright.Connection do
  @moduledoc """
  Stateful, `GenServer` based connection to a Playwright node.js server.
  The connection is established via `PhoenixTest.Playwright.Port`.

  You won't usually have to use this module directly.
  `PhoenixTest.Playwright` uses this under the hood.
  """
  use GenServer

  alias PhoenixTest.Playwright.Config
  alias PhoenixTest.Playwright.PortServer

  @timeout_grace_factor 1.5
  @min_genserver_timeout to_timeout(second: 1)

  defstruct status: :pending,
            awaiting_started: [],
            initializers: %{},
            guid_subscribers: %{},
            posts_in_flight: %{}

  @name __MODULE__

  def start_link do
    GenServer.start_link(__MODULE__, :no_init_arg, name: @name, timeout: Config.global(:timeout))
  end

  @doc """
  Launch a browser and return its `guid`.
  """
  def launch_browser(type, opts) do
    ensure_started()

    types = initializer("Playwright")
    type_id = Map.fetch!(types, type).guid

    timeout =
      opts[:browser_launch_timeout] || opts[:timeout] || Config.global(:browser_launch_timeout)

    params =
      opts
      |> Map.new()
      |> Map.put(:timeout, timeout)

    case post(guid: type_id, method: :launch, params: params) do
      %{result: %{browser: %{guid: guid}}} ->
        guid

      %{error: %{error: %{name: "TimeoutError", stack: stack, message: message}}} ->
        raise """
        Timed out while launching the Playwright browser, #{String.capitalize("#{type}")}. #{message}

        You may need to increase the :browser_launch_timeout option in config/test.exs:

            config :phoenix_test,
              playwright: [
                browser_launch_timeout: 10_000,
                # other Playwright options...
              ],
              # other phoenix_test options...

        Playwright backtrace:

        #{stack}
        """
    end
  end

  defp ensure_started do
    case Process.whereis(@name) do
      nil -> start_link()
      pid -> {:ok, pid}
    end

    GenServer.call(@name, :awaiting_started)
  end

  @doc """
  Subscribe to messages for a guid and its descendants.
  """
  def subscribe(pid \\ self(), guid) do
    GenServer.cast(@name, {:subscribe, {pid, guid}})
  end

  @doc """
  Handle a parsed message from the PortServer.
  This is called by PortServer after parsing complete messages from the Port.
  """
  def handle_playwright_msg(msg) do
    GenServer.cast(@name, {:playwright_msg, msg})
  end

  @doc """
  Post a message and await the response.
  We wait for an additional grace period after the timeout that we pass to playwright.
  """
  def post(msg, timeout \\ nil) do
    default = %{params: %{}, metadata: %{}}

    msg =
      msg
      |> Enum.into(default)
      |> update_in(~w(params timeout)a, &(&1 || timeout || Config.global(:timeout)))

    call_timeout = max(@min_genserver_timeout, round(msg.params.timeout * @timeout_grace_factor))
    GenServer.call(@name, {:post, msg}, call_timeout)
  end

  @doc """
  Get the initializer data for a channel.
  """
  def initializer(guid) do
    GenServer.call(@name, {:initializer, guid})
  end

  @impl GenServer
  def init(:no_init_arg) do
    {:ok, _} = PortServer.start_link(self())
    msg = %{guid: "", params: %{sdk_language: :javascript}, method: :initialize, metadata: %{}}
    PortServer.post(msg)

    {:ok, %__MODULE__{}}
  end

  @impl GenServer
  def handle_cast({:subscribe, {recipient, guid}}, state) do
    subscribers = Map.update(state.guid_subscribers, guid, [recipient], &[recipient | &1])
    {:noreply, %{state | guid_subscribers: subscribers}}
  end

  def handle_cast({:playwright_msg, msg}, state) do
    state = handle_recv(msg, state)
    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:post, msg}, from, state) do
    msg_id = fn -> System.unique_integer([:positive, :monotonic]) end
    msg = msg |> Map.new() |> Map.put_new_lazy(:id, msg_id)
    PortServer.post(msg)

    {:noreply, Map.update!(state, :posts_in_flight, &Map.put(&1, msg.id, from))}
  end

  def handle_call({:initializer, guid}, _from, state) do
    {:reply, Map.get(state.initializers, guid), state}
  end

  def handle_call(:awaiting_started, from, %{status: :pending} = state) do
    {:noreply, Map.update!(state, :awaiting_started, &[from | &1])}
  end

  def handle_call(:awaiting_started, _from, %{status: :started} = state) do
    {:reply, :ok, state}
  end

  defp handle_recv(msg, state) do
    state
    |> log_js(msg)
    |> add_initializer(msg)
    |> handle_started(msg)
    |> reply_in_flight(msg)
    |> send_to_subscribers(msg)
  end

  defp log_js(state, %{method: :page_error} = msg) do
    if module = Config.global(:js_logger) do
      module.log(:error, msg.params.error, msg)
    end

    state
  end

  defp log_js(state, %{method: :console} = msg) do
    if module = Config.global(:js_logger) do
      level =
        case msg[:params][:type] do
          "error" -> :error
          "debug" -> :debug
          _ -> :info
        end

      module.log(level, msg.params.text, msg)
    end

    state
  end

  defp log_js(state, _), do: state

  defp handle_started(state, %{method: :__create__, params: %{type: "Playwright"}}) do
    for from <- state.awaiting_started, do: GenServer.reply(from, :ok)
    %{state | status: :started, awaiting_started: :none}
  end

  defp handle_started(state, _), do: state

  defp add_initializer(state, %{method: :__create__} = msg) do
    Map.update!(state, :initializers, &Map.put(&1, msg.params.guid, msg.params.initializer))
  end

  defp add_initializer(state, _), do: state

  defp reply_in_flight(%{posts_in_flight: in_flight} = state, msg) when is_map_key(in_flight, msg.id) do
    {from, in_flight} = Map.pop(in_flight, msg.id)
    GenServer.reply(from, msg)

    %{state | posts_in_flight: in_flight}
  end

  defp reply_in_flight(state, _), do: state

  defp send_to_subscribers(state, %{guid: guid} = msg) do
    for pid <- Map.get(state.guid_subscribers, guid, []) do
      send(pid, {:playwright, msg})
    end

    state
  end

  defp send_to_subscribers(state, _), do: state
end
