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

To install the `instrumental-tools` package via Chef, you'll need to add our repository and package to your Chef scripts.

## Repository dependency

If you are using Berkshelf, you can add the `packagecloud` dependency to your `Berksfile`:

```sh
cookbook "packagecloud"
```

Alternatively, you can add the `packagecloud` dependency from the [OpsCode community](https://supermarket.chef.io/cookbooks/packagecloud).

Afterwards, add a dependency on our package repository via the following:

```ruby
packagecloud_repo "expectedbehavior/instrumental" do
  type "deb" # or "rpm" or "gem"
end
```

## Package

Install the `instrumental-tools` package via:

```ruby
package "instrumental-tools" do
    action :install
end
```

# Puppet

To install the `instrumental-tools` package via Puppet, you'll need to add our repository and package to your Puppet scripts.

## Repository dependency

Add the [`packagecloud` module](https://forge.puppetlabs.com/computology/packagecloud) dependency to your Puppet scripts, and then add a dependency on our repository via:

```sh
include packagecloud

packagecloud::repo { "expectedbehavior/instrumental":
 type => 'rpm',  # or "deb"
}
```

## Package

```sh
package { "instrumental-tools":
    ensure => "installed"
}
```
