import Config

config :logger, :console,
  level: :debug,
  format: "$time $metadata[$level] $message\n"

config :phoenix, :json_library, Jason

# Default WebSocket URL (can be overridden by BINANCE_WS_URL env var)
config :binance_websocket_client, :ws_url, "wss://stream.binance.com:9443/ws/btcusdt@ticker"

# Phoenix Endpoint configuration for Channels
config :binance_websocket_client, BinanceWebsocketClientWeb.Endpoint,
  url: [host: "localhost"],
  http: [ip: {127, 0, 0, 1}, port: 4000],
  secret_key_base: "J3V7+q2Cw0mwv3q5Q8nQF2k9e1vB7YwC1fP6sZrTyU9lXo3b5S8Hk2LmN9QvR2tA",
  server: true,
  pubsub_server: BinanceWebsocketClient.PubSub
