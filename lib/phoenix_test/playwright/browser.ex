defmodule PhoenixTest.Playwright.Browser do
  @moduledoc """
  Interact with a Playwright `Browser`.

  There is no official documentation, since this is considered Playwright internal.

  References:
  - https://github.com/microsoft/playwright/blob/main/packages/playwright-core/src/client/browser.ts
  """

  import PhoenixTest.Playwright.Connection, only: [post: 1]

  @doc """
  Start a new browser context and return its `guid`.
  """
  def new_context(browser_id, opts \\ []) do
    params = Map.new(opts)

    [guid: browser_id, method: :new_context, params: params]
    |> post()
    |> PhoenixTest.Playwright.Result.from_response(& &1.result.context.guid)
  end
end
