# Building instrumental-tools

## The Gem

Building the `instrumental_tools` gem can be done via:

```
rake gem
```

This will produce a .gem file suitable for release. As a shortcut for the RubyGems release process, you can issue the following command:

```
rake release
```

to push a new copy of the gem directly to RubyGems. This presumes you have the correct `rubygems_api_key` available in your system Gem config.

## `deb`, `rpm` and `tgz` packages

Building new `deb`, `rpm` and `tgz` packages can be done via the following rake commands:

For 32 bit Linux:

```
rake package:linux-x86:package # builds `rpm` and `deb`
rake package:linux-x86:tarball # buidls tgz
```

For 64 bit Linux:

```
rake package:linux-x86_64:package
rake package:linux-x86_64:tarball
```


For Mac OS X:

```
rake package:osx:tarball
```

`deb` and `rpm` packages should be pushed to PackageCloud. You will need to ensure you have the `package_cloud` gem installed (`bundle install` should install it for you - see the [PackageCloud instructions](https://packagecloud.io/docs#cli_install) otherwise). You will also need write credentials to PackageCloud available in `~/.packagecloud`; they will follow the format:

```
{"url":"https://packagecloud.io","token":"YOUR PACKAGECLOUD API TOKEN"}
```

On release, the tarball should be uploaded to the Github releases page and linked to from the main README.md.

## `exe` packages

In order to build the Windows installer, you'll need to have [NSIS](http://nsis.sourceforge.net/Main_Page) and [Mono](http://www.mono-project.com/) installed. If you're using Mac OS X, run the following commands:

```
brew install makensis
brew install mono
```

To build the installer:

```
rake package:win32:package
```
