import Config

config :phoenix_test, endpoint: PhoenixTest.WebApp.Endpoint

import_config "#{config_env()}.exs"
