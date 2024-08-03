ExUnit.start()

# Define the mock module
Mox.defmock(BinanceWebsocketClient.WebSocketClientMock, for: WebSockex)

# Set the global mode for Mox
Application.put_env(
  :binance_websocket_client,
  :websocket_client,
  BinanceWebsocketClient.WebSocketClientMock
)
