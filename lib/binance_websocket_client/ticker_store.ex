defmodule BinanceWebsocketClient.TickerStore do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    Logger.info("Starting TickerStore with name: #{inspect(name)}")
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: name])
  end

  def update(ticker_data, name \\ __MODULE__) do
    GenServer.call(name, {:update, ticker_data})
  end

  def get_latest(name \\ __MODULE__) do
    GenServer.call(name, :get_latest)
  end

  def subscribe(pid, name \\ __MODULE__) do
    GenServer.call(name, {:subscribe, pid})
  end

  def unsubscribe(pid, name \\ __MODULE__) do
    GenServer.call(name, {:unsubscribe, pid})
  end

  @impl true
  def init(:ok) do
    Logger.info("Initializing TickerStore")
    {:ok, %{ticker: nil, subscribers: []}}
  end

  @impl true
  def handle_call({:update, ticker_data}, _from, state) do
    Logger.debug("Updating ticker data: #{inspect(ticker_data)}")
    new_state = %{state | ticker: ticker_data}
    notify_subscribers(new_state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:get_latest, _from, state) do
    Logger.debug("Getting latest ticker data")
    {:reply, state.ticker, state}
  end

  @impl true
  def handle_call({:subscribe, pid}, _from, state) do
    Logger.info("New subscriber: #{inspect(pid)}")
    new_state = %{state | subscribers: [pid | state.subscribers]}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:unsubscribe, pid}, _from, state) do
    Logger.info("Unsubscribing: #{inspect(pid)}")
    new_state = %{state | subscribers: List.delete(state.subscribers, pid)}
    {:reply, :ok, new_state}
  end

  defp notify_subscribers(state) do
    Enum.each(state.subscribers, fn pid ->
      Logger.debug("Notifying subscriber: #{inspect(pid)}")
      send(pid, {:ticker_update, state.ticker})
    end)
  end

  @impl true
  def terminate(reason, _state) do
    Logger.warning("TickerStore terminating. Reason: #{inspect(reason)}")
  end
end
