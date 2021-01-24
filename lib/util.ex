defmodule Binoculo.Util do
  @version "1.0.0"
  @commands %{
    "--help | -h" => "Show Binoculo usage",
    "--ip" => "CIDR notation/ip_range -> 192.168.0.1/24|192.168.0.1..192.168.0.255",
    "-p | --port" => "Port to scan",
    "--head" => "Send a http HEAD to server",
    "-t | --threads" => "Number of threads",
    "-r | --read" => "Search for especific word in response",
    "--verbose" => "Show refused / error connections"
  }

  def help() do
    IO.puts("\nBinoculo #{@version} - Usage:")
    @commands
    |> Enum.map(fn({command, description}) -> IO.puts("#{command} - #{description}") end)

    IO.puts("\nEx: bin/binoculo --ip \"192.168.0.1/24\" -p 8080 -t 45 --head")
  end
end
