defmodule BinanceWebsocketClient.Starter do
  @moduledoc false
  use GenServer
  require Logger

  @retry_ms 15_000

  # Public API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    state = %{opts: opts, ws_pid: nil}
    # Attempt to connect immediately after init
    send(self(), :connect)
    {:ok, state}
  end

  @impl true
  def handle_info(:connect, %{ws_pid: nil} = state) do
    Logger.info("Starter attempting to connect to Binance WebSocket")

    case BinanceWebsocketClient.start_link(state.opts) do
      {:ok, pid} ->
        Logger.info("Binance WebSocket started: #{inspect(pid)}")
        ref = Process.monitor(pid)
        {:noreply, Map.put(state, :ws_pid, {pid, ref})}

      {:error, %WebSockex.RequestError{code: code} = reason} ->
        Logger.error("Binance WebSocket start failed (HTTP #{code}). Will retry in #{@retry_ms} ms. Reason: #{inspect(reason)}")
        Process.send_after(self(), :connect, @retry_ms)
        {:noreply, state}

      {:error, reason} ->
        Logger.error("Binance WebSocket start failed. Will retry in #{@retry_ms} ms. Reason: #{inspect(reason)}")
        Process.send_after(self(), :connect, @retry_ms)
        {:noreply, state}
    end
  end

  def handle_info(:connect, state) do
    # Already connected; ignore extra connect messages
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, reason}, %{ws_pid: {pid, ref}} = state) do
    Logger.warning("Binance WebSocket process #{inspect(pid)} went down: #{inspect(reason)}. Retrying in #{@retry_ms} ms")
    Process.demonitor(ref, [:flush])
    Process.send_after(self(), :connect, @retry_ms)
    {:noreply, %{state | ws_pid: nil}}
  end

  def handle_info(_msg, state), do: {:noreply, state}
end
