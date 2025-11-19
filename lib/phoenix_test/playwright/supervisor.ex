defmodule PhoenixTest.Playwright.Supervisor do
  @moduledoc false

  use Supervisor

  alias PhoenixTest.Playwright.Config

  def start_link do
    Supervisor.start_link(__MODULE__, :no_init_arg, name: __MODULE__)
  end

  @impl true
  def init(:no_init_arg) do
    playwright_config = Keyword.take(Config.global(), ~w(timeout js_logger assets_dir runner)a)
    children = [{PlaywrightEx.Supervisor, playwright_config}, PhoenixTest.Playwright.BrowserPoolSupervisor]
    Supervisor.init(children, strategy: :rest_for_one)
  end
end
