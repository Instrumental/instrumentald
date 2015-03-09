# Instrumental Tools

A collection of scripts useful for monitoring servers and services with Instrumental ([www.instrumentalapp.com](http://www.instrumentalapp.com/)).

## instrument_server

Monitor server activity by collecting information on CPU and memory usage, disk IO, filesystem usage, etc.

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

### NOTEs

Mac OS users: Due to a bug in Ruby, instrument_server can occasionally deadlock ([bug report](http://bugs.ruby-lang.org/issues/5811)).

## Troubleshooting & Help

We are here to help. Email us at [support@instrumentalapp.com](mailto:support@instrumentalapp.com), or visit the [Instrumental Support](https://fastestforward.campfirenow.com/6b934) Campfire room.
