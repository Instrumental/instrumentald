# Installation

Prebuilt `deb` and `rpm` packages are available via [packagecloud.io](https://packagecloud.io/expectedbehavior/instrumental/). These files are also available to download directly, via the [releases page](https://github.com/Instrumental/instrumentald/releases).

## OSX/macOS

### Via Homebrew

```
brew install instrumental/instrumentald/instrumentald
```

The [Homebrew formula](https://github.com/Instrumental/homebrew-instrumentald/blob/master/Formula/instrumentald.rb) does not add `/etc/instrumentald.toml` or set `instrumentald` to run at startup. It's intended to make it easier to kick the tires, not for production metric gathering.

### `pkg` Installer

Download the pkg from the [releases page](https://github.com/Instrumental/instrumentald/releases), run it, then edit `/etc/instrumentald.toml` to configure.

To make `instrumentald` run at startup, run:

```sh
launchctl load /opt/instrumentald/lib/app/osx/instrumentald.plist
```

## Ubuntu

```sh
sudo apt-get install curl
curl https://packagecloud.io/install/repositories/expectedbehavior/instrumental/script.deb.sh | sudo bash
sudo apt-get install instrumentald
```

## Debian

```sh
su -c "apt-get install curl"
su -c "curl https://packagecloud.io/install/repositories/expectedbehavior/instrumental/script.deb.sh | bash"
su -c "apt-get install instrumentald"
```

## Enterprise Linux (CentOS, AWS Linux, RedHat)

```sh
curl https://packagecloud.io/install/repositories/expectedbehavior/instrumental/script.rpm.sh | sudo bash
sudo yum install instrumentald
```

## Other ( CoreOS, et al )

### Installing the software

```sh
sudo mkdir -p /opt/instrumentald/
sudo tar -zxvf ./instrumentald_1.0.0_linux-x86_64.tar.gz -C /opt/instrumentald/ --strip 1
sudo cp /opt/instrumentald/etc/instrumentald.toml /etc/
```

### Adding to system startup

#### systemd

```sh
sudo cp /opt/instrumentald/lib/app/systemd/instrumentald.service  /etc/systemd/system/
sudo systemctl enable instrumentald.service
sudo systemctl start instrumentald
```

#### sysvinit (update-rc.d)

```sh
sudo cp /opt/instrumentald/lib/app/debian/instrumentald /etc/init.d/
sudo update-rc.d instrumentald defaults
sudo /etc/init.d/instrumentald start
```

#### sysvinit (chkconfig)

```sh
sudo cp /opt/instrumentald/lib/app/rpm/instrumentald /etc/init.d/
sudo chkconfig --add instrumentald
sudo chkconfig instrumentald on
sudo service instrumentald start
```

## Chef

An example Chef cookbook for installing `instrumentald` is available in [`chef/instrumentald`](chef/instrumentald).

## Puppet

An example Puppet module for installing `instrumentald` is available in [`puppet/instrumentald`](puppet/instrumentald).
