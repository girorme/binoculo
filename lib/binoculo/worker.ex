defmodule Binoculo.Worker do
  @moduledoc """
  Main Worker
  """

  alias Binoculo.{Config, Util}

  @type host() :: String.t()
  @type host_port() :: integer()
  @type banner() :: String.t()

  @spec get_banner(host(), host_port()) :: {:ok, banner()} | {:error, term()}
  def get_banner(host, port, timeout \\ :timer.seconds(2)) do
    with {:ok, socket} <- estabilish_connection(host, port, timeout),
         {:ok, socket} <- send_payload(socket, host, port),
         {:ok, response} <- recv_response(socket, timeout) do
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

  def estabilish_connection(host, port, timeout) do
    with host <- String.to_charlist(host),
         {:ok, host} <- :inet.parse_address(host),
         {:ok, socket} <- :gen_tcp.connect(host, port, [active: false], timeout) do
      {:ok, socket}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def send_payload(socket, host, port) do
    payload =
      case get_service_type_by_port!(port) do
        :http -> "HEAD / HTTP/1.1\r\nHost: #{host}\r\n\r\n"
        :tcp -> ""
      end

    # User write payload
    payload =
      if write_payload = Config.get_write_payload() do
        case String.ends_with?(write_payload, "\r\n\r\n") do
          true -> write_payload
          false -> "#{write_payload}\r\n\r\n"
        end
      else
        payload
      end

    case :gen_tcp.send(socket, payload) do
      :ok -> {:ok, socket}
      {:error, reason} -> {:error, reason}
    end
  end

  def recv_response(socket, timeout), do: :gen_tcp.recv(socket, 0, timeout)

  defp get_service_type_by_port!(port) do
    case port in Util.get_possible_http_ports() do
      true -> :http
      _ -> :tcp
    end
  end
end
