# Instrumental Server Monitoring Daemon

Instrumental is a [applicationg platform](https://instrumentalapp.com) built for developers who want a better understanding of their production software. Powerful tools, like the [Instrumental Query Language](https://instrumentalapp.com/docs/query-language), combined with an exploration-focused interface allow you to get real answers to complex questions, in real-time.

This tool suite supports [server monitoring](https://instrumentalapp.com/docs/server-monitoring) through the `instrumental_server` daemon. It provides high-data reliability at high scale.

## Installation
`instrumentald` is currently officially supported on 32-bit and 64-bit Linux, Windows systems and Mac OS X. There are prebuilt packages available for Debian, Ubuntu, RHEL and Win32 systems.

Installation instructions for supported platforms is available in [INSTALL.md](INSTALL.md). The recommended installation method is to use a prebuilt package, which will automatically install the application as a service in your operating system's startup list.

Once you've installed the package, you will want to edit the `/etc/instrumentald.toml` file with your [Instrumental project token](https://instrumentalapp.com/docs/tokens). Example `/etc/instrumentald.toml`:

```toml
api_key = "YOUR_PROJECT_API_TOKEN"
```

## Metrics

By default, Instrumental Daemon will collect metrics on the following server data:

* CPU (`user`, `nice`, `system`, `idle`, `iowait` and `total in use`)
* Load (at 1 minute, 5 minute and 15 minute intervals)
* Memory (`used`, `free`, `buffers`, `cached`, `free_percent` )
* Swap (`used`, `free`, `free_percent`)
* Disk Capacity (`total`, `used`, `available`, `available percent` for all mounted disks)
* Disk Usage (`percent_utilization` for all mounted disks)
* Filesystem stats (`open_files`, `max_open_files`)

#### Monitoring Services & Other Processes

Instrumental Daemon monitors other processes through a powerful plugin system built on binary and shell scripts. Plugin installation and development instructions are listed in [PLUGIN_SCRIPTS.md](PLUGIN_SCRIPTS.md). Existing plugins include:

* [MySQL](examples/mysql)
* [Mongo](examples/mongo)
* [Docker](examples/docker)
* [Redis](examples/redis)

## Command Line Usage

Basic usage:

```sh
instrumentald -k <API_KEY>
```

To start `instrumentald` as a daemon:

```sh
instrumentald -k <API_KEY> start
```

The API key can also be provided by setting the INSTRUMENTAL_TOKEN environment variable, which eliminates the need to supply the key via command line option.

By default, instrumentald will use the hostname of the current host when reporting metrics, e.g. 'hostname.cpu.in_use'. To specify a different hostname:

```sh
instrumentald -k <API_KEY> -H <HOSTNAME>
```

The `start` command will start and detach the process. You may issue additional commands to the process like:

* `stop` - stop the currently running `instrumentald` process
* `restart` - restart the currently running `instrumentald` process
* `foreground` - run the process in the foreground instead of detaching
* `status` - display daemon status (running, stopped)
* `clean` - remove any files created by the daemon
* `kill` - forcibly halt the daemon and remove its pid file


### Capistrano Integration

Add `require "instrumentald/capistrano"` to your capistrano
configuration and `instrumentald` will be restarted after your
deploy is finished. Additionally, you will need to add a new variable
to your capistrano file.

```ruby
set :instrumental_key, "API_KEY"
```

The following configuration will be added:

```ruby
after "deploy", "instrumental:restart_instrumentald"
after "deploy:migrations", "instrumental:restart_instrumentald"
```

By default, this will attempt to restart the `instrumentald` command
on all the servers specified in your configuration. If you need to
limit the servers on which you restart the server, you can do
something like this in your capistrano configuration:

```ruby
namespaces[:instrumental].tasks[:restart_instrumentald].options[:roles] = [:web, :worker]
```

## Troubleshooting & Help

We are here to help! Email us at [support@instrumentalapp.com](mailto:support@instrumentalapp.com).
