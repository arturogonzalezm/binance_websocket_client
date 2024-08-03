defmodule BinanceWebsocketClient do
  use WebSockex
  require Logger

  @websocket_client Application.compile_env(:binance_websocket_client, :websocket_client, WebSockex)

  def start_link(opts \\ []) do
    Logger.info("Starting BinanceWebsocketClient")
    url = "wss://stream.binance.com:9443/ws/btcusdt@ticker"
    @websocket_client.start_link(url, __MODULE__, %{ticker_store: Keyword.get(opts, :ticker_store, BinanceWebsocketClient.TickerStore)}, opts)
  end

  def handle_connect(_conn, state) do
    Logger.info("Connected to Binance WebSocket")
    {:ok, state}
  end

  def handle_disconnect(%{reason: {:local, reason}}, state) do
    Logger.warning("Local disconnect: #{inspect(reason)}")
    {:ok, state}
  end

  def handle_disconnect(disconnect_map, state) do
    Logger.warning("Disconnected: #{inspect(disconnect_map)}")
    {:reconnect, state}
  end

  def handle_frame({:text, msg}, state) do
    Logger.debug("Received message: #{msg}")
    case Jason.decode(msg) do
      {:ok, event} ->
        Logger.debug("Decoded event: #{inspect(event)}")
        handle_event(event, state.ticker_store)
      {:error, reason} ->
        Logger.error("Error decoding JSON: #{inspect(reason)}")
    end
    {:ok, state}
  end

  def handle_frame(frame, state) do
    Logger.warning("Received unexpected frame: #{inspect(frame)}")
    {:ok, state}
  end

  defp handle_event(%{"e" => "24hrTicker", "s" => "BTCUSDT"} = event, ticker_store) do
    Logger.info("Handling BTCUSDT ticker event")
    case BinanceWebsocketClient.TickerStore.update(event, ticker_store) do
      :ok -> :ok
      {:error, reason} ->
        Logger.error("Failed to update TickerStore: #{inspect(reason)}")
    end
  end

  defp handle_event(event, _ticker_store) do
    Logger.warning("Received unknown event: #{inspect(event)}")
  end

  def handle_info({:handle_frame, {:text, msg}}, state) do
    handle_frame({:text, msg}, state)
  end
end
