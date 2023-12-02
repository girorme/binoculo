defmodule BinoculoDaemon.Util do
  @moduledoc """
  Util functions
  """

  @ip_common_re ~r/^(\d{1,3}\.){3}\d{1,3}$/
  @ip_cidr_re ~r/^([0-9]{1,3}\.){3}[0-9]{1,3}(\/([0-9]|[1-2][0-9]|3[0-2]))?$/
  @ip_range_re ~r/^(([0-9]{1,3}\.){3}[0-9]{1,3})\.\.(?1)$/

  alias IP

  def parse_range_or_cidr_notation(notation) do
    cond do
      Regex.match?(@ip_common_re, notation) ->
        IP.Subnet.from_string(notation <> "/32")

      Regex.match?(@ip_cidr_re, notation) ->
        IP.Subnet.from_string(notation)

      Regex.match?(@ip_range_re, notation) ->
        IP.Range.from_string(notation)

      true ->
        {:error, "invalid_format"}
    end
  end

  def format_http_response(http_response) do
    header_and_body = parse_header_and_body(http_response)

    [http_code | key_value] = String.split(header_and_body[:header], "\r\n")

    resp =
      for session <- key_value, into: %{} do
        [key, value] = String.split(session, ": ", parts: 2)
        {key, value}
      end

    Map.put(
      resp,
      "Code",
      http_code
    )
  end

  def get_possible_http_ports(), do: [8080, 80, 443]

  defp parse_header_and_body(http_response) do
    case String.split(http_response, "\r\n\r\n") do
      [header, body] -> %{header: header, body: body}
      header -> %{header: Enum.at(header, 0), body: nil}
    end
  end
end
