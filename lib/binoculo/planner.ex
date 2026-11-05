defmodule Binoculo.Planner do
  @moduledoc """
  Calculates the scan size (hosts x ports) and splits it into balanced partitions.

  Nothing is materialized: hosts are addressed by their integer offset from the
  first IP, so a /0 costs the same as a /32.
  """

  alias Binoculo.Util

  defstruct [
    :first_int,
    :total_hosts,
    :ports,
    :total_units,
    :partitions,
    :concurrency,
    :timeout
  ]

  @type partition :: %{
          index: non_neg_integer(),
          start: non_neg_integer(),
          len: pos_integer(),
          concurrency: pos_integer()
        }

  @type t :: %__MODULE__{}

  @max_default_concurrency 1000
  @default_timeout 500
  # descriptors the VM keeps for itself (stdio, files, the API server...)
  @reserved_fds 256

  @doc """
  Default concurrency: 1000, lowered to fit the open files limit (`ulimit -n`)
  of this process, otherwise most connections would fail with `emfile`.
  """
  def default_concurrency(), do: concurrency_for(nofile_limit())

  @doc false
  def concurrency_for(:unknown), do: @max_default_concurrency
  def concurrency_for(:infinity), do: @max_default_concurrency

  def concurrency_for(nofile) when is_integer(nofile),
    do: nofile |> Kernel.-(@reserved_fds) |> max(1) |> min(@max_default_concurrency)

  @doc "Soft limit of open files for this process, or `:unknown` where it can't be read."
  def nofile_limit() do
    with {:ok, content} <- File.read("/proc/self/limits"),
         [_, soft] <- Regex.run(~r/^Max open files\s+(\S+)/m, content) do
      case Integer.parse(soft) do
        {n, ""} -> n
        _ -> :infinity
      end
    else
      _ -> :unknown
    end
  end

  @doc "Whether `concurrency` plus the reserved descriptors exceeds the open files limit."
  def exceeds_nofile?(concurrency) do
    case nofile_limit() do
      n when is_integer(n) -> concurrency + @reserved_fds > n
      _ -> false
    end
  end

  def default_timeout(), do: @default_timeout

  @doc """
  Builds the scan plan.

  Options: `:concurrency` (global max simultaneous connections), `:partitions`
  (wanted number of partitions) and `:timeout` (ms, per connect/recv).
  The effective number of partitions never exceeds the units or the concurrency.
  """
  @spec build(String.t(), [integer()], keyword()) :: {:ok, t()} | {:error, String.t()}
  def build(host_notation, ports, opts \\ []) do
    concurrency = Keyword.get(opts, :concurrency, default_concurrency())
    partitions = Keyword.get(opts, :partitions, System.schedulers_online())
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    with :ok <- validate_positive(:concurrency, concurrency),
         :ok <- validate_positive(:partitions, partitions),
         :ok <- validate_positive(:timeout, timeout),
         :ok <- validate_ports(ports),
         {:ok, range} <- Util.parse_range_or_cidr_notation(host_notation),
         {:ok, first_ip, total_hosts} <- range_info(range) do
      total_units = total_hosts * length(ports)
      effective_partitions = Enum.min([partitions, total_units, concurrency])

      partitions =
        split(total_units, effective_partitions)
        |> Enum.zip(split(concurrency, effective_partitions))
        |> Enum.with_index()
        |> Enum.map(fn {{{start, len}, {_, c}}, index} ->
          %{index: index, start: start, len: len, concurrency: c}
        end)

      {:ok,
       %__MODULE__{
         first_int: IP.to_integer(first_ip),
         total_hosts: total_hosts,
         ports: List.to_tuple(ports),
         total_units: total_units,
         partitions: partitions,
         concurrency: concurrency,
         timeout: timeout
       }}
    end
  end

  @doc """
  Splits `n` items into `p` contiguous `{start, len}` slices whose sizes differ by at most 1.
  """
  @spec split(non_neg_integer(), pos_integer()) :: [{non_neg_integer(), non_neg_integer()}]
  def split(n, p) do
    base = div(n, p)
    extra = rem(n, p)

    for i <- 0..(p - 1) do
      {i * base + min(i, extra), base + if(i < extra, do: 1, else: 0)}
    end
  end

  @doc """
  Lazy stream of `{host, port}` for a partition (all ports of a host are adjacent).
  """
  @spec targets(t(), partition()) :: Enumerable.t()
  def targets(%__MODULE__{} = plan, %{start: start, len: len}) do
    n_ports = tuple_size(plan.ports)

    Stream.map(start..(start + len - 1), fn unit ->
      host =
        (plan.first_int + div(unit, n_ports))
        |> IP.from_integer(:v4)
        |> IP.to_string()

      {host, elem(plan.ports, rem(unit, n_ports))}
    end)
  end

  defp range_info(%IP.Subnet{routing_prefix: first} = subnet),
    do: {:ok, first, Enum.count(subnet)}

  defp range_info(%IP.Range{first: first} = range), do: {:ok, first, Enum.count(range)}

  defp validate_ports([_ | _]), do: :ok
  defp validate_ports(_ports), do: {:error, "at least one port is required"}

  defp validate_positive(_name, value) when is_integer(value) and value > 0, do: :ok
  defp validate_positive(name, _value), do: {:error, "#{name} must be a positive integer"}
end
