defmodule BinanceWebsocketClientWeb.TickerChannel do
  use Phoenix.Channel

  alias BinanceWebsocketClient.TickerStore

  @topic "ticker:btcusdt"

  def topic, do: @topic

  @impl true
  def join("ticker:" <> _pair = _topic, _params, socket) do
    # Defer pushing until after the socket has joined
    case TickerStore.get_latest() do
      nil -> :ok
      latest -> send(self(), {:after_join, latest})
    end

    {:ok, socket}
  end

  @impl true
  def handle_info({:after_join, latest}, socket) do
    push(socket, "latest", latest)
    {:noreply, socket}
  end

  @impl true
  def handle_in(_event, _payload, socket) do
    {:noreply, socket}
  end
end
