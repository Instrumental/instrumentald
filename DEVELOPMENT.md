# Development

If you don't have [Homebrew](http://brew.sh/index.html) installed, install it! Then, run:

```
script/setup
```

If you haven't, make sure go is set up and you have a `GOPATH` environment var.

```sh
export GOPATH=SOME_DIRECTORY_HERE # see https://golang.org/cmd/go/#hdr-GOPATH_environment_variable
```

Install Telegraf:
```
go get github.com/influxdata/telegraf
```

## Making Changes to instrumentald

See [TEST.md](TEST.md) for instructions on running tests.

### Changing Metrics Collected

`instrumentald` uses Telegraf to collect metrics, but does so in a opinionated way. It decides which metrics to collect and how those metrics should be namespaced to best work with Instrumental and it's query language. To add or change which metrics are collected (inputs, in Telegraf parlance), edit `lib/telegraf/telegraf.conf.erb`.

#### Adding a new input

Adding a new input will almost certainly mean adding a new config option. That will mean editing `server_controller.rb`, plus the following default/example confs:

```
conf/instrumentald.toml
puppet/instrumentald/templates/instrumentald.toml.erb
chef/instrumentald/templates/default/instrumentald.toml.erb
```

In most cases, that config will be an array of some kind, probably URLs. Check out the patterns in `server_controller.rb` for existing inputs (e.g, mySQL) to see how that config value is used to render `telegraf.conf.erb`.

`instrumentald` should only collect the most valuable metrics. Which are the most valuable? You decide! Directionally, we want fewer metrics that are high value. We do not want "collect all the thing!".

See existing input configs in `telegraf.conf.erb` for how to limit the metrics collected. The Telegraf [configuration docs](https://github.com/influxdata/telegraf/blob/master/docs/CONFIGURATION.md) are very helpful in this regard. A hint: you *may* need to include multiple blocks for each input (e.g, docker).

Also, be sure the namespacing of the new metrics makes sense and doesn't collide with another existing (or potential future) input.

## Making Changes to Telegraf

```
cd "$GOPATH/src/github.com/influxdata/telegraf"
# Add our fork as a remote
git remote add instrumental git@github.com:Instrumental/telegraf.git
brew install gdm # go dependency manager
make # will install dependencies
```

Then, do work!
```
git checkout -b my-feature

# work hard for a while

make test-short # should pass

git push instrumental my-feature

# PR that feature on Telegraf
```

If you've done this before and are working on new changes, make sure master of our fork gets updated with Telegraf master!
