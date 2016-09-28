# Building instrumentald

## Linux

To build everything, use the following command:

```
rake package
```

Building new `deb`, `rpm` and `tgz` packages can be done via the following rake commands:

For 32 bit Linux:

```
rake package:linux-x86:package # builds `rpm` and `deb`
rake package:linux-x86:compress # builds tgz
```

For 64 bit Linux:

```
rake package:linux-x86_64:package
rake package:linux-x86_64:compress
```

`deb` and `rpm` packages should be pushed to PackageCloud. You will need to ensure you have the `package_cloud` gem installed (`bundle install` should install it for you - see the [PackageCloud instructions](https://packagecloud.io/docs#cli_install) otherwise). You will also need write credentials to PackageCloud available in `~/.packagecloud`; they will follow the format:

```
{"url":"https://packagecloud.io","token":"YOUR PACKAGECLOUD API TOKEN"}
```

And then use the package_cloud gem to push our packages.  For example:

```
rake package:release
```

On release, the tarball should be uploaded to the Github releases page and linked to from the main README.md.

## macOS

To build for macOS, you need to be running macOS. This is because of cross-compilation issues with one of the dependencies of telegraf.

There are 2 builds for macOS:

1. a pkg
2. a tarball

Both should be uploaded to GitHub when making a release.

To make both, do:

```
rake package:osx
```
