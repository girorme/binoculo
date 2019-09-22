defmodule Binoculo.Util do
  @version "1.0.0"
  @commands %{
    "--help | -h" => "Show Binoculo usage",
    "--ip" => "CIDR notation/ip_range"
  }

  def help() do
    IO.puts("\nBinoculo #{@version} - Usage:")
    @commands
    |> Enum.map(fn({command, description}) -> IO.puts("#{command} - #{description}") end)
  end
end
