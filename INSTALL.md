# Ubuntu

```sh
sudo apt-get install curl
curl https://packagecloud.io/install/repositories/expectedbehavior/instrumental/script.deb | sudo bash
sudo apt-get install instrumental-tools
```

# Debian

```sh
su -c "apt-get install curl"
su -c "curl https://packagecloud.io/install/repositories/expectedbehavior/instrumental/script.deb | bash"
su -c "apt-get install instrumental-tools"
```

# Enterprise Linux (CentOS, AWS Linux, RedHat)

```sh
curl https://packagecloud.io/install/repositories/expectedbehavior/instrumental/script.rpm | sudo bash
sudo yum install instrumental-tools
```

# Other ( CoreOS, et al )

## Installing the software

```sh
sudo mkdir -p /opt/instrumental-tools/
sudo tar -zxvf ./instrumental-tools_1.0.0.rc2_linux-x86_64.tar.gz -C /opt/instrumental-tools/ --strip 1
sudo cp /opt/instrumental-tools/etc/instrumental.yml /etc/
```

# RubyGems

```sh
sudo gem install instrumental_tools
```

Installing `instrumental_tools` via Rubygems will not create the `/opt/instrumental-tools/` directory on your server or setup the process to run on startup. It is advisable that you install the software via the `deb` or `rpm` packages if your system supports its.

## Adding to system startup

### systemd

```sh
sudo cp /opt/instrumental-tools/lib/app/systemd/instrument_server.service  /etc/systemd/system/
sudo systemctl enable instrument_server.service
sudo systemctl start instrument_server
```

### sysvinit (update-rc.d)

```sh
sudo cp /opt/instrumental-tools/lib/app/debian/instrument_server /etc/init.d/
sudo update-rc.d instrument_server defaults
sudo /etc/init.d/instrument_server start
```

### sysvinit (chkconfig)

```sh
sudo cp /opt/instrumental-tools/lib/app/rpm/instrument_server /etc/init.d/
sudo chkconfig --add instrument_server
sudo chkconfig instrument_server on
sudo service instrument_server start
```

# Chef

An example Chef cookbook for installing `instrumental-tools` is available in (`chef/instrumental_tools`)[chef/instrumental_tools].

# Puppet

An example Puppet module for installing `instrumental-tools` is available in (`puppet/instrumental_tools`)[puppet/instrumental_tools].
