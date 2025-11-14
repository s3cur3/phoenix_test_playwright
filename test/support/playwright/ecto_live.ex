defmodule PhoenixTest.Playwright.EctoLive do
  @moduledoc false
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <h1>{@result}</h1>
    """
  end

  def mount(_params, _session, socket) do
    %{rows: [result]} = PhoenixTest.Playwright.Repo.query!("SELECT version()")
    {:ok, assign(socket, :result, result)}
  end
end
