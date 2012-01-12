# Instrumental Tools

A collection of scripts useful for monitoring servers and services with Instrumental ([www.instrumentalapp.com](http://www.instrumentalapp.com/)).

## instrument_server

Monitor server activity by collecting information on CPU and memory usage, disk IO, filesystem usage, etc.

```sh
instrument_server -k <API_KEY>
```

The API key can also be provided by setting the INSTRUMENTAL_TOKEN environment variable, which eliminates the need to supply the key via command line option.

NOTE for Mac OS users: Due to a bug in Ruby, instrument_server can occasionally deadlock ([bug report](http://bugs.ruby-lang.org/issues/5811)).

## instrumental

Output text graphs of the different metrics in your project.

See all options with: `instrumental --help`

## gitstrumental

Collect commit counts from git repositories.

```sh
cd project_directory
gitstrumental <API_KEY>
```

## Capistrano Integration

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
