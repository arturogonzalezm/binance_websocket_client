defmodule BinanceWebsocketClientWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :binance_websocket_client

  socket "/socket", BinanceWebsocketClientWeb.UserSocket,
    websocket: [connect_info: [:peer_data]],
    longpoll: false

  # Serve static assets for the dashboard
  plug Plug.Static,
    at: "/",
    from: :binance_websocket_client,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt index.html styles.css app.js)

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug Plug.MethodOverride
  plug Plug.Head

  plug :serve_index

  defp serve_index(%Plug.Conn{request_path: "/"} = conn, _opts) do
    path = Application.app_dir(:binance_websocket_client, "priv/static/index.html")
    case File.read(path) do
      {:ok, html} ->
        conn
        |> Plug.Conn.put_resp_content_type("text/html; charset=utf-8")
        |> Plug.Conn.send_resp(200, html)
      {:error, _} ->
        Plug.Conn.send_resp(conn, 200, "Binance Websocket Client")
    end
  end

  defp serve_index(conn, _opts), do: Plug.Conn.send_resp(conn, 404, "Not Found")
end
