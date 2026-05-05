defmodule PhoenixTest.Playwright.EventRecorder do
  @moduledoc false
  use GenServer

  defstruct [:filter, events: [], waiter: nil]

  def pop(name, timeout) do
    GenServer.call(name, {:pop, timeout}, :infinity)
  end

  def start_link(%{guid: _, filter: _} = args, opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  @impl GenServer
  def init(%{guid: guid, filter: filter}) when is_function(filter, 1) do
    PlaywrightEx.subscribe(guid, pid: self())
    {:ok, %__MODULE__{filter: filter}}
  end

  @impl GenServer
  def handle_call({:pop, _timeout}, _from, %{events: [event | events]} = state) do
    {:reply, {:ok, event}, %{state | events: events}}
  end

  def handle_call({:pop, timeout}, from, %{events: [], waiter: nil} = state) do
    Process.send_after(self(), :pop_timeout, timeout)
    {:noreply, %{state | waiter: from}}
  end

  def handle_call({:pop, _timeout}, _from, _state) do
    raise "EventRecorder already has a pending pop"
  end

  @impl GenServer
  def handle_info({:playwright_msg, event}, %__MODULE__{} = state) do
    if state.filter.(event) do
      {:noreply, record_event(event, state)}
    else
      {:noreply, state}
    end
  end

  def handle_info(:pop_timeout, %{waiter: nil} = state), do: {:noreply, state}

  def handle_info(:pop_timeout, %{waiter: waiter} = state) do
    GenServer.reply(waiter, {:error, :timeout})
    {:noreply, %{state | waiter: nil}}
  end

  defp record_event(event, %__MODULE__{waiter: nil, events: events} = state) do
    %{state | events: events ++ [event]}
  end

  defp record_event(event, %__MODULE__{waiter: waiter} = state) do
    GenServer.reply(waiter, {:ok, event})
    %{state | waiter: nil}
  end
end
