# Development

If you don't have [Homebrew](http://brew.sh/index.html) installed, install it! Then, run:

```
script/setup
```

See [TEST.md](TEST.md) for instructions on running tests.

If you haven't, make sure go is set up and you have a `GOPATH` environment var.

```sh
export GOPATH=SOME_DIRECTORY_HERE # see https://golang.org/cmd/go/#hdr-GOPATH_environment_variable
```

To get started, install Telegraf:
```
go get github.com/influxdata/telegraf
cd "$GOPATH/src/github.com/influxdata/telegraf"
```

Then add our fork as a remote:

```
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
