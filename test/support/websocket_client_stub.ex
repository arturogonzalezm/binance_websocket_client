defmodule BinanceWebsocketClient.WebSocketClientStub do
  @behaviour WebSockex

  def start_link(_url, module, state, _opts) do
    {:ok, spawn_link(fn -> loop(module, state) end)}
  end

  defp loop(module, state) do
    receive do
      {:send, {type, msg}} ->
        module.handle_frame({type, msg}, state)
        loop(module, state)
    end
  end

  def send_frame(pid, frame) do
    send(pid, {:send, frame})
    :ok
  end

  # Implement required callbacks with default behavior
  def handle_connect(_conn, state), do: {:ok, state}
  def handle_frame(_frame, state), do: {:ok, state}
  def handle_cast(_msg, state), do: {:ok, state}
  def handle_info(_msg, state), do: {:ok, state}
  def handle_ping(_ping, state), do: {:ok, state}
  def handle_pong(_pong, state), do: {:ok, state}
  def handle_disconnect(_disconnect_map, state), do: {:ok, state}
  def terminate(_reason, _state), do: :ok
  def code_change(_old_vsn, state, _extra), do: {:ok, state}
end
