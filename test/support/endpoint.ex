defmodule PhoenixTest.Endpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :phoenix_test_playwright

  socket("/live", Phoenix.LiveView.Socket)

  plug(Plug.Static, at: "/", from: :phoenix_test_playwright)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart],
    pass: ["*/*"]
  )

  plug(Plug.MethodOverride)
  plug(PhoenixTest.Router)
end
