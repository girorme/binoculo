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
--head - Send a http HEAD to server
--help | -h - Show Binoculo usage
--ip - CIDR notation/ip_range -> 192.168.0.1/24|192.168.0.1..192.168.0.255
-p | --port - Port to scan
-t | --threads - Number of threads

Ex: bin/binoculo --ip "192.168.0.1/24" -p 8080 -t 45 --head
```

Two options are allowed to scan range of ips:

Using cidr:
- 192.168.0.1/24

Using range:
- 192.168.0.1..192.168.0.255

Example

### Simple service banner grab

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

### Grab http services

- With `--head` param is possible to query http services
- Is also possible to get specific words in response using the  `-r/--read` param

```
$ bin/binoculo --ip 177.72.255.184/24 -p 80 --head
```
- Using `-r` param

```
$ bin/binoculo --ip 177.72.255.184/24 -p 80 --head -r "Apache"
```

## Todo
- Improve release binaries
