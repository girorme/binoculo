defmodule BinoculoDaemon.Stub.Server do
  @moduledoc """
  Module used to stub a server connection in tests
  """

  def start(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [
        :binary,
        :inet,
        {:active, false},
        {:reuseaddr, true},
        {:ip, {0, 0, 0, 0}}
      ])

    loop_accept(socket)
  end

  @spec loop_accept(port | {:"$inet", atom, any}) :: no_return
  def loop_accept(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    spawn(fn -> handle_client(client) end)
    loop_accept(socket)
  end

  def handle_client(socket) do
    send_response(socket, "220 FTP Server ready.\r\n")
    loop_receive_commands(socket)
  end

  def loop_receive_commands(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        handle_command(socket, String.trim(data))
        loop_receive_commands(socket)

      {:error, :closed} ->
        :ok

      {:error, reason} ->
        IO.puts("Socket error: #{reason}")
        :ok
    end
  end

  def handle_command(socket, command) do
    case String.upcase(command) do
      "USER" ->
        send_response(socket, "331 Username OK, need password.\r\n")

      "PASS" ->
        send_response(socket, "230 Password OK.\r\n")

      "QUIT" ->
        send_response(socket, "221 Goodbye.\r\n")
        :gen_tcp.close(socket)

      _ ->
        send_response(socket, "502 Command not implemented.\r\n")
    end
  end

  def send_response(socket, message) do
    :gen_tcp.send(socket, message)
  end
end
