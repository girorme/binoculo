defmodule BinoculoDaemon.Stub.Server do
  @moduledoc """
  Module used to stub a server connection in tests
  """

  def start(port, expected_banner) do
    {:ok, socket} =
      :gen_tcp.listen(port, [
        :binary,
        :inet,
        {:active, false},
        {:reuseaddr, true},
        {:ip, {0, 0, 0, 0}}
      ])

    loop_accept(socket, expected_banner)
  end

  def loop_accept(socket, expected_banner) do
    {:ok, client} = :gen_tcp.accept(socket)
    spawn(fn -> handle_client(client, expected_banner) end)
    loop_accept(socket, expected_banner)
  end

  def handle_client(socket, expected_banner) do
    send_response(socket, expected_banner)
  end

  def send_response(socket, message) do
    :gen_tcp.send(socket, message)
  end
end
