defmodule BinanceWebsocketClientWeb.TickerBroadcaster do
  use GenServer
  require Logger
  alias BinanceWebsocketClient.TickerStore
  alias BinanceWebsocketClientWeb.{Endpoint, TickerChannel}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting TickerBroadcaster and subscribing to TickerStore")

    case TickerStore.subscribe(self()) do
      :ok -> :ok
      other -> Logger.error("Failed to subscribe to TickerStore: #{inspect(other)}")
    end

    {:ok, %{}}
  end

  @impl true
  def handle_info({:ticker_update, ticker}, state) do
    Logger.debug("Broadcasting ticker update to channel: #{inspect(ticker)}")
    Endpoint.broadcast!(TickerChannel.topic(), "update", ticker)
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}
end
