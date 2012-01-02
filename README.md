# Instrumental Tools

A collection of tools for use with Instrumental ([www.instrumental.com](http://www.instrumentalapp.com/))

## instrument_server

Use to collect various monitoring statistics of a server. Execute with:

```sh
instrument_server -k <INSTRUMENTAL_API_KEY>
```

Linux note: Install iostat (part of the sysstat package) in order to collect disk I/O metrics.

Mac OS note: Due to a bug in Ruby, instrument_server can occasionally deadlock ([bug report](http://bugs.ruby-lang.org/issues/5811)).

## instrumental

Output text graphs of the different metrics in your project.

See all options with: `instrumental --help`

## gitstrumental

Collect statistics on commit counts in a given git repo.  Execute in the repo directory with:

```sh
gitstrumental [INSTRUMENTAL_API_KEY]
```

## Capistrano Integration

Add `require "instrumental_tools/capistrano"` to your capistrano
configuration and instrument_server will be restarted after your
deploy is finished. Additionally, you will need to add a new variable
to your capistrano file.

```ruby
set :instrumental_key, "YOUR_KEY_HERE"
```

The following configuration will be added:

```ruby
after "deploy", "instrumental:restart_instrument_server"
after "deploy:migrations", "instrumental:restart_instrument_server"
```
