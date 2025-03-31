defmodule Binoculo.Api.Router do
  @moduledoc false

  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/status" do
    send_resp(conn, 200, "Binoculo is running!")
  end

  post "/start" do
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    params = Jason.decode!(body)

    host_notation = params["host_notation"]
    ports = params["ports"]
    read = params["read"]
    page = String.to_integer(params["page"] || "1")
    page_size = String.to_integer(params["page_size"] || "10")

    result = Binoculo.Api.Service.get_banners(host_notation, ports, read, page, page_size)

    send_resp(conn, 200, Jason.encode!(result))
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
