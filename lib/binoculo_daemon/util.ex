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
end
