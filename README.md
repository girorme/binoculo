# Binoculo

**Just another banner grab made in elixir**

## Installation

Get the last binary in the release page (requires `erlang`) or compile from source (requires `elixir` to use mix):

```
$ git clone https://github.com/girorme/binoculo
$ mix deps.get
$ mix escript.build
```

After `mix escript.build` command a binary is builded in the `bin` folder.

## Usage

Parameters
```
--help | -h - Show Binoculo usage
--ip - CIDR notation/ip_range -> 192.168.0.1/24|192.168.0.1..192.168.0.255
-p | --port - Port to scan
-t | --threads - Number of threads (Default: 30)
```

Two options are allowed to scan range of ips:

Using cidr:
- 192.168.0.1/24

Using range:
- 192.168.0.1..192.168.0.255

Example

```
$ bin/binoculo --ip 192.168.0.1..192.168.0.2 -p 22
Binoculo cli


[] 192.168.0.1
--
SSH-2.0-dropbear_2012.55
...
...
...
```

## Todo
- Improve release binaries
- Add user banner pattern match
- Add output to file
