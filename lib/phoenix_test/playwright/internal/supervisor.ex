defmodule PhoenixTest.Playwright.Supervisor do
  @moduledoc false

  use Supervisor

  alias PhoenixTest.Playwright.Config

  def start_link do
    Supervisor.start_link(__MODULE__, :no_init_arg, name: __MODULE__)
  end

  @impl true
  def init(:no_init_arg) do
    config = Config.global()
    playwright_config = [executable: Config.executable()] ++ Keyword.take(config, ~w(timeout js_logger)a)
    children = [{PlaywrightEx.Supervisor, playwright_config}, PhoenixTest.Playwright.BrowserPoolSupervisor]
    Supervisor.init(children, strategy: :rest_for_one)
  end
end
