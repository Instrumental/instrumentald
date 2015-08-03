# Instrumental Tools

A collection of tools for monitoring servers with Instrumental ([www.instrumentalapp.com](http://www.instrumentalapp.com/)).

## Operating System Support

`instrumental_tools` is currently officially supported on 32-bit and 64-bit Linux, Windows systems and Mac OS X. There are prebuilt packages available for Debian, RHEL and Win32 systems.

## Installation

Installation instructions for supported platforms is available in [INSTALL.md](INSTALL.md). The recommended installation method is to use a prebuilt package, which will automatically install the application as a service in your operating system's startup list.

Once you've installed the package, you will want to edit the `/etc/instrumental.yml` file with your Instrumental API key. Example `/etc/instrumental.yml`:

## Sent Metrics

The default `instrument_server` behavior will collect metrics on the following data:

* CPU (`user`, `nice`, `system`, `idle`, `iowait` and `total in use`)
* Load (at 1 minute, 5 minute and 15 minute intervals)
* Memory (`used`, `free`, `buffers`, `cached`, `free_percent` )
* Swap (`used`, `free`, `free_percent`)
* Disk Capacity (`total`, `used`, `available`, `available percent` for all mounted disks)
* Disk Usage (`percent_utilization` for all mounted disks)
* Filesystem stats (`open_files`, `max_open_files`)

## Command Line Usage

Basic usage:

```sh
instrument_server -k <API_KEY>
```

The API key can also be provided by setting the INSTRUMENTAL_TOKEN environment variable, which eliminates the need to supply the key via command line option.

By default, instrument_server will use the hostname of the current host when reporting metrics, e.g. 'hostname.cpu.in_use'. To specify a different hostname:

```sh
instrument_server -k <API_KEY> -H <HOSTNAME>
```

### Running as a Daemon

To start instrument_server as a daemon:

```
instrument_server -k <API_KEY> start
```

The `start` command will start and detach the process. You may issue additional commands to the process like:

* `start` - start and detach the process
* `stop` - stop the currently running `instrument_server` process
* `restart` - restart the currently running `instrument_server` process
* `foreground` - run the process in the foreground instead of detaching
* `status` - display daemon status (running, stopped)
* `clean` - remove any files created by the daemon
* `kill` - forcibly halt the daemon and remove its pid file

### Custom Metrics

You can create custom scripts whose output will be sent to Instrumental every time `instrument_server` checks in. You can read more about how to create these scripts at [CUSTOM_METRICS.md](CUSTOM_METRICS.md).


### Capistrano Integration

Add `require "instrumental_tools/capistrano"` to your capistrano
configuration and instrument_server will be restarted after your
deploy is finished. Additionally, you will need to add a new variable
to your capistrano file.

```ruby
set :instrumental_key, "API_KEY"
```

The following configuration will be added:

```ruby
after "deploy", "instrumental:restart_instrument_server"
after "deploy:migrations", "instrumental:restart_instrument_server"
```

By default, this will attempt to restart the instrument_server command
on all the servers specified in your configuration. If you need to
limit the servers on which you restart the server, you can do
something like this in your capistrano configuration:

```ruby
namespaces[:instrumental].tasks[:restart_instrument_server].options[:roles] = [:web, :worker]
```

### NOTES

Mac OS users: Due to a bug in Ruby, instrument_server can occasionally deadlock ([bug report](http://bugs.ruby-lang.org/issues/5811)).

## Troubleshooting & Help

We are here to help. Email us at [support@instrumentalapp.com](mailto:support@instrumentalapp.com), or visit the [Instrumental Support](https://fastestforward.campfirenow.com/6b934) Campfire room.
