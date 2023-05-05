defmodule BinoculoDaemon.Worker do
  @moduledoc """
  Main Worker
  """

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

  @spec get_service_type_by_port!(port :: host_port()) :: atom()
  defp get_service_type_by_port!(port) do
    case port in [80, 443] do
      true -> :http
      _ -> :tcp
    end
  end

  @spec estabilish_connection(host(), host_port()) ::
          {:ok, port()} | {:error, reason :: term()}
  defp estabilish_connection(host, port) do
    with host <- String.to_charlist(host),
         {:ok, host} <- :inet.parse_address(host),
         {:ok, socket} <- :gen_tcp.connect(host, port, [active: false], :timer.seconds(2)) do
      {:ok, socket}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec send_payload(port(), host(), host_port()) ::
          {:ok, port()} | {:error, reason :: String.t()}
  defp send_payload(socket, host, port) do
    payload =
      case get_service_type_by_port!(port) do
        :http -> "HEAD / HTTP/1.1\r\nHost: #{host}\r\n\r\n"
        :tcp -> ""
      end

    case :gen_tcp.send(socket, payload) do
      :ok -> {:ok, socket}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec recv_response(port()) :: {:ok, response :: term()} | {:error, reason :: String.t()}
  defp recv_response(socket), do: :gen_tcp.recv(socket, 0)
end
