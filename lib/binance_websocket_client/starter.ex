defmodule BinanceWebsocketClient.Starter do
  @moduledoc false
  use GenServer
  require Logger

  @retry_ms 15_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    Logger.info("Starter initializing; will attempt to connect to Binance WebSocket")
    state = %{opts: opts, client: nil}
    send(self(), :connect)
    {:ok, state}
  end

  @impl true
  def handle_info(:connect, state) do
    Logger.info("Attempting to start BinanceWebsocketClient...")

    case safe_start_client(state.opts) do
      {:ok, pid} ->
        Logger.info("BinanceWebsocketClient started (pid=#{inspect(pid)})")
        Process.monitor(pid)
        {:noreply, %{state | client: pid}}

      {:error, reason} ->
        Logger.error(
          "Failed to start BinanceWebsocketClient: #{inspect(reason)}. Retrying in #{@retry_ms / 1000}s..."
        )

        schedule_retry()
        {:noreply, %{state | client: nil}}
    end
  end

  @impl true
  def handle_info({:DOWN, _mref, :process, pid, reason}, %{client: pid} = state) do
    Logger.warning(
      "BinanceWebsocketClient terminated (pid=#{inspect(pid)}): #{inspect(reason)}. Retrying in #{@retry_ms / 1000}s..."
    )

    schedule_retry()
    {:noreply, %{state | client: nil}}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}

  defp schedule_retry do
    Process.send_after(self(), :connect, @retry_ms)
  end

  defp safe_start_client(opts) do
    BinanceWebsocketClient.start_link(opts)
  catch
    kind, err ->
      {:error, {kind, err}}
  end
end
