# BinoculoDaemon

## Commands
```
Binoculo: You Know, for Banner Grabbing! Version: 0.1.0
Author: Girorme <g1r0rm3@gmail.com>
A banner grabbing tool

USAGE:
    Binoculo [--dashboard] [-v] --range host_notation [--port port]
    Binoculo --version
    Binoculo --help

FLAGS (under construction):

    --dashboard        Launches a shodan like dashboard                                                              
    -v                 Verbosity level                                                                               

OPTIONS:

    -r, --range        CIDR or IP range: 192.168.1.0/24 or 192.168.1.0..192.168.1.255                                
    -p, --port         Port(s) to scan
```

## Usage
1. Start meilisearch to store results:
```
$ docker run -d -it --rm -p 7700:7700  -v $(pwd)/meili_data:/meili_data getmeili/meilisearch:v1.1
```

2. Run some scan
```
$ ./binoculo -r 15.197.142.173/20 -p 22
```

3. Access meilisearch to see results on `http://localhost:7700/`

---

In the future we'll be able to acess a better page to use shodan like filters

## Architecture
![image](https://user-images.githubusercontent.com/54730507/236296988-4a6c5579-dcaa-4b23-bbce-121b814473df.png)
