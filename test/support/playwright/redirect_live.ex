defmodule PhoenixTest.Playwright.RedirectLive do
  @moduledoc false
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <h1>You shouldn't see this</h1>
    """
  end

  def mount(%{"redirect_type" => redirect_type}, _, socket) do
    case redirect_type do
      "push_navigate" ->
        {:ok, push_navigate(socket, to: "/pw/live/index")}

      "redirect" ->
        {:ok, redirect(socket, to: "/pw/live/index")}
    end
  end
end
