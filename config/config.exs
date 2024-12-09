import Config

config :phoenix_test,
  endpoint: PhoenixTest.Endpoint

import_config "#{config_env()}.exs"
