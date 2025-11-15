defmodule PhoenixTest.Endpoint do
  @moduledoc """
  Copied from https://github.com/germsel/phoenix_test

  This support file helps run upstream tests against the Playwright driver to ensure continued compatability with the `pheonix_test` API.
  It is copied regularly.

  This file should be changed as little as possible, to make future updates easy.
  """
  use Phoenix.Endpoint, otp_app: :phoenix_test_playwright

  @session_options [
    store: :cookie,
    key: "_phoenix_key",
    signing_salt: "KUJB95ho",
    same_site: "Lax"
  ]

  socket("/live", Phoenix.LiveView.Socket,
    # connect_info: causes tests to fail (CSRF token?)
    # [connect_info: [:user_agent, session: @session_options]],
    websocket: [],
    longpoll: false
  )

  plug(Plug.Static,
    at: "/",
    from: :phoenix_test_playwright,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt)
  )

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(PhoenixTest.Router)

  def session_options, do: @session_options
end
