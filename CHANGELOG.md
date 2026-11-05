# Changelog

## 1.4.0

Faster scans of large ranges (`/16` and up) and scan timing in the output.

### Added
- Scan start time, end time and durations (scan, saving results, total) plus rate in units/s
  (a unit is one `host:port`) in the output.
- `--concurrency` (default `1000`, lowered to fit `ulimit -n` when it is low): real limit of
  simultaneous connections. A warning is printed if the chosen value exceeds the open files limit.
- `--partitions` (default: CPU cores): the work (`hosts x ports`) is calculated up front and split
  into balanced parts (sizes differ by at most 1) that are scanned in parallel.
- `--timeout` (default `500` ms): connect/read timeout per `host:port`.
- Defaults (`--concurrency 1000`, `--timeout 500`) favour speed. Measured on a `/18`, port 22:
  5000/2000 found 20 banners in 8s (lost SYNs from the burst), 1000/500 found 31 in 9s,
  1000/3000 found 48 in 51s, 300/2000 found 54 in 1m54s. Use `--timeout 3000` to miss fewer hosts.
- `connect/timeout` in the error breakdown shows a yellow hint: `try increasing the timeout with
  --timeout <ms> - now: 500ms, default: 500ms` (no colors if `NO_COLOR` is set).
- Scan plan printed before starting (units, partitions, concurrency, timeout).
- Summary with banners, errors, resource errors (file descriptors/ports exhausted on this machine)
  and units not processed. Resource errors are no longer hidden as "host did not answer".
- Error breakdown in the summary by stage and reason (`connect/timeout`, `connect/econnrefused`,
  `recv/timeout` = connected but no banner, `recv/closed`, ...), so dropped hosts can be explained.
- `--errors-output <file>`: saves every failed `host:port stage reason` to `output/<file>` for
  debugging (opt-in: it keeps one row per failure in memory).
- The docker launcher shows local time instead of UTC on Linux hosts.
- The docker launcher raises the container open files limit (`--ulimit nofile=65536:65536`); the
  docker default of 1024 made most connections of a `/16` fail with `emfile`.

### Changed
- Results are stored one row per result and progress uses counters. Registering a result no longer
  copies the whole result list (it was quadratic: `/16` with more ports got much slower).
- Progress refreshes 10 times per second reading only counters (it was a busy loop copying all results).
- The total of hosts is calculated, not enumerated.
- `Binoculo.Maestro` is no longer a GenServer; `Maestro.run/2` runs the plan. A crashed
  partition does not stop the others and is reported in the summary.
- `Worker.get_banner/4` accepts a `write_payload` option (read once instead of one `Config` call
  per connection), closes the socket and returns the error `reason`.

### Fixed
- Files created in `output/` were owned by root and could not be deleted from the host. The launcher
  now runs the container as your user and creates `output/` itself. If `output/` already belongs to
  root (older runs), it stops with the `sudo chown` command to fix it once.
- A response header without a space after the colon (`X-XSS-Protection:1; mode=block`) crashed the
  run while saving to Meilisearch, before the summary. The parser now accepts it and a failing result
  can no longer abort the run.
- The old `max_concurrency: 200` did not limit the connections (it only limited a `cast`), so a
  big range opened all of them at once. The limit is real now.
- The scan could hang forever when every worker finished before the first progress check.
- A descending range (`192.168.0.10..192.168.0.1`) crashed instead of returning an invalid range error.
- Concluding a port no longer removes the other ports of the same host from the in-progress state.

### Not changed
- Output file format, Meilisearch documents/ids and the HTTP API (`POST /scan`).
