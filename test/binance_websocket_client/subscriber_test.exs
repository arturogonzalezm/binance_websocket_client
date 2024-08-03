defmodule BinanceWebsocketClient.SubscriberTest do
  use ExUnit.Case, async: true
  alias BinanceWebsocketClient.{Subscriber, TickerStore}

  setup do
    store_name = :"TickerStore#{System.unique_integer()}"
    {:ok, _store} = start_supervised({TickerStore, name: store_name})
    %{store_name: store_name}
  end

  test "subscriber receives updates", %{store_name: store_name} do
    test_pid = self()
    handler = fn ticker -> send(test_pid, {:handled, ticker}) end
    {:ok, _pid} = Subscriber.start_link(handler: handler, ticker_store: store_name)

    ticker_data = %{"price" => "53000", "volume" => "400"}
    TickerStore.update(ticker_data, store_name)

    assert_receive {:handled, ^ticker_data}
  end

  test "subscriber with filter", %{store_name: store_name} do
    test_pid = self()
    handler = fn ticker -> send(test_pid, {:handled, ticker}) end
    filter = fn ticker -> String.to_integer(ticker["volume"]) > 500 end

    {:ok, _pid} =
      Subscriber.start_link(handler: handler, filter: filter, ticker_store: store_name)

    # This update should not pass the filter
    TickerStore.update(%{"price" => "54000", "volume" => "400"}, store_name)
    refute_receive {:handled, _}

    # This update should pass the filter
    ticker_data = %{"price" => "55000", "volume" => "600"}
    TickerStore.update(ticker_data, store_name)
    assert_receive {:handled, ^ticker_data}
  end
end
