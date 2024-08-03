defmodule BinanceWebsocketClient.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Starting BinanceWebsocketClient.Application")
    children = [
      {BinanceWebsocketClient.TickerStore, []},
      {BinanceWebsocketClient, []}
    ]

    opts = [strategy: :one_for_one, name: BinanceWebsocketClient.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Logger.info("BinanceWebsocketClient.Application started successfully")
        {:ok, pid}
      {:error, reason} ->
        Logger.error("Failed to start BinanceWebsocketClient.Application: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @impl true
  def stop(_state) do
    Logger.info("Stopping BinanceWebsocketClient.Application")
    :ok
  end
end
