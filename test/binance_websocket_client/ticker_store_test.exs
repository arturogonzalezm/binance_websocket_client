defmodule BinanceWebsocketClient.TickerStoreTest do
  use ExUnit.Case, async: true
  alias BinanceWebsocketClient.TickerStore

  setup do
    {:ok, store} = start_supervised({TickerStore, name: :"TickerStore#{System.unique_integer()}"})
    %{store: store}
  end

  test "updates and retrieves latest ticker data", %{store: store} do
    ticker_data = %{"price" => "50000", "volume" => "100"}
    :ok = TickerStore.update(ticker_data, store)
    assert TickerStore.get_latest(store) == ticker_data
  end

  test "subscribes and notifies subscribers", %{store: store} do
    ticker_data = %{"price" => "51000", "volume" => "200"}

    :ok = TickerStore.subscribe(self(), store)
    :ok = TickerStore.update(ticker_data, store)

    assert_receive {:ticker_update, ^ticker_data}
  end

  test "unsubscribes successfully", %{store: store} do
    :ok = TickerStore.subscribe(self(), store)
    :ok = TickerStore.unsubscribe(self(), store)

    TickerStore.update(%{"price" => "52000", "volume" => "300"}, store)

    refute_receive {:ticker_update, _}
  end
end
