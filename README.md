# BinoculoDaemon

Binoculo is a lightning-fast banner grabbing tool built with Elixir, designed to swiftly retrieve service banners from target hosts. With its high-speed functionality, Binoculo efficiently collects service information across multiple ports, aiding in network reconnaissance and analysis.

## Commands
```
Binoculo: You Know, for Banner Grabbing! Version: 0.1.0
Author: Girorme <g1r0rm3@gmail.com>
A banner grabbing tool

USAGE:
    Binoculo [--dashboard] [-v] --range host_notation --port port(s)
    Binoculo --version
    Binoculo --help

FLAGS:

    --dashboard        Launches a shodan like dashboard                                      
    -v                 Verbosity level                                                       

OPTIONS:

    -r, --range        CIDR or IP range: 192.168.1.0/24 or 192.168.1.0..192.168.1.255        
    -p, --port         Port(s) to scan: 80,443,8080 or 80-8080 or 21,80-8080
```

## Usage
1. Start meilisearch to store results:
```
$ docker run -d -it --rm -p 7700:7700  -v $(pwd)/meili_data:/meili_data getmeili/meilisearch:v1.1
```

2. Run

**Via docker**
```
$ docker run --rm --pull always ghcr.io/girorme/binoculo:main -r 192.168.101.1/24 -p 21,22
```

**Via your host machine (requires elixir > 1.14)**
```
$ ./binoculo -r 192.168.1.0/20 -p 22
```

3. Access meilisearch to see results on `http://localhost:7700/`

---

In the future we'll be able to acess a better page to use shodan like filters

## Architecture
![image](https://user-images.githubusercontent.com/54730507/236296988-4a6c5579-dcaa-4b23-bbce-121b814473df.png)
