defmodule PhoenixTest.Playwright.Page do
  @moduledoc """
  Interact with a Playwright `Page`.

  There is no official documentation, since this is considered Playwright internal.

  References:
  - https://github.com/microsoft/playwright/blob/main/packages/playwright-core/src/client/page.ts
  """

  import PhoenixTest.Playwright.Connection, only: [post: 1]

  def screenshot(page_id, opts \\ []) do
    # Playwright options: https://playwright.dev/docs/api/class-page#page-screenshot
    params =
      opts
      |> Keyword.validate!(full_page: true, omit_background: false)
      |> Map.new()

    [guid: page_id, method: :screenshot, params: params]
    |> post()
    |> unwrap_response(& &1.result.binary)
  end

  defp unwrap_response(response, fun) do
    case response do
      %{error: _} = error -> {:error, error}
      _ -> {:ok, fun.(response)}
    end
  end
end
