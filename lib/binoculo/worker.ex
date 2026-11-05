defmodule Binoculo.Worker do
  @moduledoc """
  Main Worker
  """

  alias Binoculo.{Config, Util}

  @type host() :: String.t()
  @type host_port() :: integer()
  @type banner() :: String.t()

  @doc """
  Grabs the banner of `host:port`.

  Options: `:write_payload` overrides the payload stored in `Binoculo.Config`
  (pass it when scanning in bulk to avoid one `Config` call per unit).
  """
  @spec get_banner(host(), host_port(), timeout(), keyword()) ::
          {:ok, map()} | {:error, map()}
  def get_banner(host, port, timeout \\ :timer.seconds(2), opts \\ []) do
    write_payload = Keyword.get_lazy(opts, :write_payload, &Config.get_write_payload/0)

    case estabilish_connection(host, port, timeout) do
      {:ok, socket} ->
        result = grab(socket, host, port, write_payload, timeout)
        :gen_tcp.close(socket)
        result

      {:error, reason} ->
        error_result(host, port, reason, :connect)
    end
  end

  defp grab(socket, host, port, write_payload, timeout) do
    with {:send, {:ok, socket}} <- {:send, send_payload(socket, host, port, write_payload)},
         {:recv, {:ok, response}} <- {:recv, recv_response(socket, timeout)} do
      {:ok, %{host: host, port: port, response: to_string(response)}}
    else
      {stage, {:error, reason}} -> error_result(host, port, reason, stage)
    end
  end

  # stage: where it failed (:connect, :send, or :recv = connected but no banner)
  defp error_result(host, port, reason, stage) do
    {:error,
     %{
       host: host,
       port: port,
       stage: stage,
       reason: reason,
       response: "Error returning banner... socket response: #{reason}"
     }}
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

  def send_payload(socket, host, port),
    do: send_payload(socket, host, port, Config.get_write_payload())

  def send_payload(socket, host, port, write_payload) do
    payload =
      case get_service_type_by_port!(port) do
        :http -> "HEAD / HTTP/1.1\r\nHost: #{host}\r\n\r\n"
        :tcp -> ""
      end

    # User write payload
    payload =
      if write_payload do
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
