defmodule BinoculoDaemon.Api.Connector do
  @moduledoc """
  Socket client "interface"
  """
  @callback get_banner(String.t(), integer()) :: {:ok, term()} | {:error, term()}
end
