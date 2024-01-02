defmodule Binoculo.Worker do
  @moduledoc """
  Main Worker
  """

  alias Binoculo.{Config, Util}

  @type host() :: String.t()
  @type host_port() :: integer()
  @type banner() :: String.t()

  @spec get_banner(host(), host_port()) :: {:ok, banner()} | {:error, term()}
  def get_banner(host, port) do
    with {:ok, socket} <- estabilish_connection(host, port),
         {:ok, socket} <- send_payload(socket, host, port),
         {:ok, response} <- recv_response(socket) do
      {:ok, %{host: host, port: port, response: to_string(response)}}
    else
      {:error, reason} ->
        {:error,
         %{
           host: host,
           port: port,
           response: "Error returning banner... socket response: #{reason}"
         }}
    end
  end

  defp get_service_type_by_port!(port) do
    case port in Util.get_possible_http_ports() do
      true -> :http
      _ -> :tcp
    end
  end

  defp estabilish_connection(host, port) do
    with host <- String.to_charlist(host),
         {:ok, host} <- :inet.parse_address(host),
         {:ok, socket} <- :gen_tcp.connect(host, port, [active: false], :timer.seconds(2)) do
      {:ok, socket}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp send_payload(socket, host, port) do
    payload =
      case get_service_type_by_port!(port) do
        :http -> "HEAD / HTTP/1.1\r\nHost: #{host}\r\n\r\n"
        :tcp -> ""
      end

    # User write payload
    payload =
      if write_payload = Config.get_write_payload() do
        write_payload
      else
        payload
      end

    # TODO: improve code readbility
    if write_payload do
      case :gen_tcp.send(socket, payload) do
        :ok ->
          # Send extra payload when user wants to write to socket
          case :gen_tcp.send(socket, "\r\n\r\n") do
            :ok -> {:ok, socket}
            {:error, reason} -> {:error, reason}
          end
        {:error, reason} ->
          {:error, reason}
      end
    else
      case :gen_tcp.send(socket, payload) do
        :ok -> {:ok, socket}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp recv_response(socket), do: :gen_tcp.recv(socket, 0, :timer.seconds(2))
end
