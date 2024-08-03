defmodule BinanceWebsocketClient.Subscriber do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    Logger.info("Starting Subscriber")
    GenServer.start_link(__MODULE__, opts)
  end

  def stop(pid) do
    Logger.info("Stopping Subscriber: #{inspect(pid)}")
    GenServer.stop(pid)
  end

  @impl true
  def init(opts) do
    state = %{
      handler: Keyword.get(opts, :handler),
      filter: Keyword.get(opts, :filter, fn _ -> true end),
      ticker_store: Keyword.get(opts, :ticker_store, BinanceWebsocketClient.TickerStore)
    }

    if state.handler == nil do
      Logger.error("No handler specified for Subscriber")
      {:stop, {:error, :no_handler_specified}}
    else
      Logger.info("Initializing Subscriber with handler: #{inspect(state.handler)}")
      case BinanceWebsocketClient.TickerStore.subscribe(self(), state.ticker_store) do
        :ok ->
          Logger.info("Successfully subscribed to TickerStore")
          {:ok, state}
        {:error, reason} ->
          Logger.error("Failed to subscribe to TickerStore: #{inspect(reason)}")
          {:stop, reason}
      end
    end
  end

  @impl true
  def handle_info({:ticker_update, ticker_data}, state) do
    Logger.debug("Received ticker update: #{inspect(ticker_data)}")
    if state.filter.(ticker_data) do
      Logger.debug("Ticker update passed filter, calling handler")
      try do
        state.handler.(ticker_data)
      rescue
        e ->
          Logger.error("Error in subscriber handler: #{inspect(e)}")
      end
    else
      Logger.debug("Ticker update did not pass filter")
    end
    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.warning("Subscriber terminating. Reason: #{inspect(reason)}")
    BinanceWebsocketClient.TickerStore.unsubscribe(self(), state.ticker_store)
    :ok
  end
end
