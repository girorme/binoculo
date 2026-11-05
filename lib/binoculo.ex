defmodule Binoculo do
  @moduledoc """
  Documentation for `Binoculo`.
  """

  alias Binoculo.{Config, CrossSaver, Results, Util, Maestro, Args, Planner}
  alias Binoculo.Api.Server

  def main(argv) do
    {:ok, parsed_args} = Args.parse_args(argv)

    server_mode =
      get_in(parsed_args, [Access.key!(:flags), Access.key!(:server)])

    case server_mode do
      true -> start_server()
      _ -> init_cli(parsed_args)
    end
  end

  defp start_server do
    IO.puts("Starting API server on port 4000")
    # start the server
    Server.start(:normal, [])
    :timer.sleep(:infinity)
  end

  def init_cli(parsed_args) do
    options = parsed_args.options
    host_notation = options.host_notation
    ports = options.ports
    port_count = Enum.count(ports)
    errors_output = Map.get(options, :errors_output)

    config = %{
      output_file: options.output,
      write_payload: options.write,
      read_payload: options.read
    }

    config
    |> Config.set_output_file()
    |> Config.set_write_payload()
    |> Config.set_read_payload()

    plan =
      case Planner.build(host_notation, ports,
             concurrency: options.concurrency,
             partitions: options.partitions,
             timeout: options.timeout
           ) do
        {:ok, plan} ->
          plan

        {:error, reason} ->
          IO.puts("Invalid scan options: #{reason}")
          System.halt(1)
      end

    started_at = Util.format_datetime()
    started_ms = System.monotonic_time(:millisecond)

    IO.puts(Util.banner())
    IO.puts("Binoculo started!")
    IO.puts("[*] Started at: #{started_at}")
    IO.puts("[*] Host: #{host_notation}")
    IO.puts("[*] Ports: #{port_count}: #{Enum.join(Enum.take(ports, 5), ", ")}...")
    IO.puts("[*] Total hosts to scan: #{plan.total_hosts}, with #{port_count} ports each")

    IO.puts(
      "[*] Units: #{plan.total_units} | Partitions: #{length(plan.partitions)} | " <>
        "Concurrency: #{plan.concurrency} | Timeout: #{plan.timeout}ms"
    )

    if plan.concurrency > :erlang.system_info(:port_limit) do
      IO.puts("[!] Concurrency is above the VM port limit; expect resource errors")
    end

    if Planner.exceeds_nofile?(plan.concurrency) do
      IO.puts(
        "[!] Concurrency is above the open files limit (ulimit -n = #{Planner.nofile_limit()}); " <>
          "expect resource errors. Raise the limit or lower --concurrency"
      )
    end

    # the results table belongs to this process, so it must be created here
    Results.init_db(length(plan.partitions), keep_errors: errors_output != nil)

    summary = scan(plan)
    scan_ms = System.monotonic_time(:millisecond) - started_ms

    IO.puts("\n\nSaving results...")

    CrossSaver.save_results()
    if errors_output, do: CrossSaver.save_errors(errors_output)

    total_ms = System.monotonic_time(:millisecond) - started_ms
    print_summary(Results.progress(), summary, plan, scan_ms, total_ms - scan_ms, total_ms)
  end

  defp scan(plan) do
    task = Task.async(fn -> Maestro.run(plan) end)
    wait_scan(task, plan.total_units)
  end

  defp wait_scan(task, total) do
    case Task.yield(task, 100) do
      nil ->
        render_progress(total)
        wait_scan(task, total)

      {:ok, summary} ->
        render_progress(total)
        summary

      {:exit, reason} ->
        exit(reason)
    end
  end

  defp render_progress(total) do
    %{done: done, ok: ok, error: error, resource_error: resource_error} = Results.progress()
    percent = Float.round(done / total * 100, 1)

    IO.write(
      "\rScanning: #{done}/#{total} (#{percent}%) | banners: #{ok} | " <>
        "errors: #{error} | resource errors: #{resource_error}   "
    )
  end

  defp print_error_breakdown([]), do: :ok

  defp print_error_breakdown(breakdown) do
    IO.puts("[*] Errors by stage/reason:")

    for {stage, reason, count} <- breakdown do
      IO.puts("      #{String.pad_trailing("#{stage}/#{reason}", 28)} #{count}")
    end
  end

  defp print_summary(progress, summary, plan, scan_ms, persist_ms, total_ms) do
    IO.puts("\n[*] Finished at: #{Util.format_datetime()}")
    IO.puts("[*] Scan: #{Util.format_duration(scan_ms)}")
    IO.puts("[*] Persist: #{Util.format_duration(persist_ms)}")
    IO.puts("[*] Total: #{Util.format_duration(total_ms)}")
    IO.puts("[*] Rate: #{Float.round(progress.done / max(scan_ms, 1) * 1000, 1)} units/s")

    IO.puts(
      "[*] Banners: #{progress.ok} | Errors: #{progress.error} | " <>
        "Resource errors: #{progress.resource_error} | Not processed: #{summary.not_processed}"
    )

    print_error_breakdown(Results.error_breakdown())

    if progress.resource_error > 0 do
      IO.puts(
        "[!] #{progress.resource_error} connection(s) failed due to local limits " <>
          "(file descriptors / ports). Lower --concurrency (now #{plan.concurrency}) or raise `ulimit -n`."
      )
    end

    if summary.failed_partitions != [] do
      IO.puts("[!] Partitions that crashed: #{inspect(summary.failed_partitions)}")
    end
  end
end
