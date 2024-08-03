defmodule BinanceWebsocketClientTest do
  use ExUnit.Case, async: true

  setup do
    store_name = :"TickerStore#{System.unique_integer()}"
    {:ok, store} = start_supervised({BinanceWebsocketClient.TickerStore, name: store_name})
    Application.put_env(:binance_websocket_client, :websocket_client, BinanceWebsocketClient.WebSocketClientStub)
    {:ok, client} = BinanceWebsocketClient.start_link(ticker_store: store_name)
    %{client: client, store: store, store_name: store_name}
  end

  test "handles ticker updates", %{client: client, store_name: store_name} do
    ticker_data = Jason.encode!(%{
      "e" => "24hrTicker",
      "s" => "BTCUSDT",
      "c" => "50000",
      "p" => "1000",
      "P" => "2"
    })

    send(client, {:handle_frame, {:text, ticker_data}})

    :timer.sleep(100)
    latest_ticker = BinanceWebsocketClient.TickerStore.get_latest(store_name)
    assert latest_ticker["e"] == "24hrTicker"
    assert latest_ticker["s"] == "BTCUSDT"
    assert is_binary(latest_ticker["c"])
    assert is_binary(latest_ticker["p"])
    assert is_binary(latest_ticker["P"])
  end

  test "ignores non-BTCUSDT updates", %{client: client, store_name: store_name} do
    ticker_data = Jason.encode!(%{
      "e" => "24hrTicker",
      "s" => "ETHUSDT",
      "c" => "3000",
      "p" => "100",
      "P" => "3"
    })

    send(client, {:handle_frame, {:text, ticker_data}})

    :timer.sleep(100)
    assert BinanceWebsocketClient.TickerStore.get_latest(store_name) == nil
  end
end
