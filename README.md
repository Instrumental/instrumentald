# Instrumental System Daemon (ISD)

** Warning: This is not production ready! **

Instrumental is an [application monitoring platform](https://instrumentalapp.com/) built for developers who want a better understanding of their production software. Powerful tools, like the [Instrumental Query Language](https://instrumentalapp.com/docs/query-language), combined with an exploration-focused interface allow you to get real answers to complex questions, in real-time.

**Instrumental System Daemon** (ISD for short) is a server agent that provides [system monitoring](#system-metrics) and [service monitoring](#service-metrics). It's fast, reliable, runs on anything *nix, is [simple to configure](conf/instrumental.toml) and deploy, and has a small memory footprint.


## Installation
`instrumentald` is supported on 32-bit and 64-bit Linux, as well as OSX/macOS. There are prebuilt packages available for Debian, Ubuntu, and RHEL systems.

Detailed installation instructions for supported platforms are available in [INSTALL.md](INSTALL.md). For linux servers, the recommended installation method is to use a prebuilt package, which will automatically install the application as a service in your operating system's startup list.

Once you've installed the package, you will want to edit the `/etc/instrumentald.toml` file with your [Instrumental project token](https://instrumentalapp.com/docs/tokens). Example `/etc/instrumentald.toml`:

```toml
project_token = "YOUR_PROJECT_TOKEN"
system = ["cpu", "disk", "load", "memory", "network", "swap"]
docker = ["unix:///var/run/docker.sock"]
memcached = ["localhost:11211"]
mongodb = ["localhost:27017"]
mysql = ["root@tcp(127.0.0.1:3306)/"]
nginx = ["http://localhost:80/status"]
postgresql = ["postgres://postgres@localhost?sslmode=disable"]
redis = ["tcp://localhost:6379"]
```

## System Metrics

Unless configured otherwise, ISD will collect system metrics from every server on which it's installed, including:

* CPU Stats
* Disk Stats
* Load Stats
* Memory Stats
* Network Stats
* Swap Stats

A detailed list of system metrics collected by ISD can be found in the [Instrumental documentation](https://instrumentalapp.com/docs/isd/system-metrics).

## Service Metrics

ISD is built to make it easy to collect the most important metrics from your critical services. It's currently capable of capturing metrics from the following services:

* [Docker](https://instrumentalapp.com/docs/isd/docker)
* [MySQL](https://instrumentalapp.com/docs/isd/mysql)
* [Memcached](https://instrumentalapp.com/docs/isd/memcached)
* [MongoDB](https://instrumentalapp.com/docs/isd/mongodb)
* [Nginx](https://instrumentalapp.com/docs/isd/nginx)
* [PostgreSQL](https://instrumentalapp.com/docs/isd/postgresql)
* [Redis](https://instrumentalapp.com/docs/isd/redis)

## Custom Plugin Scripts

ISD can monitor arbitrary processes and system events through a plugin scripting system. Writing plugins is easier than you'd think! Plugin script installation and development instructions are listed in [PLUGIN_SCRIPTS.md](PLUGIN_SCRIPTS.md), and we've got [several examples](examples/) to get you started.

## Command Line Usage

Basic usage:

```sh
instrumentald -k <PROJECT_TOKEN>
```

To start `instrumentald` as a daemon:

```sh
instrumentald -k <PROJECT_TOKEN> start
```

The project token can also be provided by setting the INSTRUMENTAL_TOKEN environment variable, which eliminates the need to supply the key via command line option.

By default, instrumentald will use the hostname of the current host when reporting metrics, e.g. 'hostname.cpu.in_use'. To specify a different hostname:

```sh
instrumentald -k <PROJECT_TOKEN> -H <HOSTNAME>
```

The `start` command will start and detach the process. You may issue additional commands to the process like:

* `stop` - stop the currently running `instrumentald` process
* `restart` - restart the currently running `instrumentald` process
* `foreground` - run the process in the foreground instead of detaching
* `status` - display daemon status (running, stopped)
* `clean` - remove any files created by the daemon
* `kill` - forcibly halt the daemon and remove its pid file

By default, instrumentald will look for a configuration file at `/etc/instrumentald.toml`. You can pass an alternatve instead:

```sh
instrumentald -k <PROJECT_TOKEN> -H <HOSTNAME> -c <PATH_TO_CONF>
```

## Troubleshooting & Help

We are here to help! Email us at [support@instrumentalapp.com](mailto:support@instrumentalapp.com).
