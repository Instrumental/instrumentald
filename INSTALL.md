# Package Locations

## PackageCloud

Prebuilt `deb` and `rpm` packages are available via the [packagecloud.io](https://packagecloud.io/) service. These files are also available to download directly:

* 64-bit Debian package (Ubuntu, Debian) [https://s3.amazonaws.com/instrumentald/1.1.2/instrumentald_1.1.2_amd64.deb](https://s3.amazonaws.com/instrumentald/1.1.2/instrumentald_1.1.2_amd64.deb)
* 32-bit Debian package (Ubuntu, Debian) [https://s3.amazonaws.com/instrumentald/1.1.2/instrumentald_1.1.2_i386.deb](https://s3.amazonaws.com/instrumentald/1.1.2/instrumentald_1.1.2_i386.deb)
* 64-bit RPM package (RHEL, Amazon AMI) [https://s3.amazonaws.com/instrumentald/1.1.2/instrumentald_1.1.2_amd64.rpm](https://s3.amazonaws.com/instrumentald/1.1.2/instrumentald_1.1.2_amd64.rpm)
* 32-bit RPM package (RHEL, Amazon AMI) [https://s3.amazonaws.com/instrumentald/1.1.2/instrumentald_1.1.2_i386.rpm](https://s3.amazonaws.com/instrumentald/1.1.2/instrumentald_1.1.2_i386.rpm)
* 64-bit Linux tarball (CoreOS, etc.) [https://s3.amazonaws.com/instrumentald/1.1.2/instrumentald_1.1.2_linux-x86_64.tar.gz](https://s3.amazonaws.com/instrumentald/1.1.2/instrumentald_1.1.2_linux-x86_64.tar.gz)
* 32-bit Linux tarball (CoreOS, etc.) [https://s3.amazonaws.com/instrumentald/1.1.2/instrumentald_1.1.2_linux-x86.tar.gz](https://s3.amazonaws.com/instrumentald/1.1.2/instrumentald_1.1.2_linux-x86.tar.gz)
* Windows installer [https://s3.amazonaws.com/instrumentald/1.1.2/instrumentald_1.1.2_win32.exe](https://s3.amazonaws.com/instrumentald/1.1.2/instrumentald_1.1.2_win32.exe)
* 64-bit Mac OS X tarball [https://s3.amazonaws.com/instrumentald/1.1.2/instrumentald_1.1.2_osx.tar.gz](https://s3.amazonaws.com/instrumentald/1.1.2/instrumentald_1.1.2_osx.tar.gz)

# Ubuntu

```sh
sudo apt-get install curl
curl https://packagecloud.io/install/repositories/expectedbehavior/instrumental/script.deb.sh | sudo bash
sudo apt-get install instrumentald
```

# Debian

```sh
su -c "apt-get install curl"
su -c "curl https://packagecloud.io/install/repositories/expectedbehavior/instrumental/script.deb.sh | bash"
su -c "apt-get install instrumentald"
```

# Enterprise Linux (CentOS, AWS Linux, RedHat)

```sh
curl https://packagecloud.io/install/repositories/expectedbehavior/instrumental/script.rpm.sh | sudo bash
sudo yum install instrumentald
```

# Other ( CoreOS, et al )

## Installing the software

```sh
sudo mkdir -p /opt/instrumentald/
sudo tar -zxvf ./instrumentald_1.0.0_linux-x86_64.tar.gz -C /opt/instrumentald/ --strip 1
sudo cp /opt/instrumentald/etc/instrumental.yml /etc/
```

# Windows

Download the [installer](https://s3.amazonaws.com/instrumentald/1.1.2/instrumentald_1.1.2_win32.exe) and run it, adding in your API key when prompted.

# RubyGems

```sh
sudo gem install instrumentald
```

Installing `instrumentald` via Rubygems will not create the `/opt/instrumentald/` directory on your server or setup the process to run on startup. It is advisable that you install the software via the `deb` or `rpm` packages if your system supports its.

## Adding to system startup

### systemd

```sh
sudo cp /opt/instrumentald/lib/app/systemd/instrumentald.service  /etc/systemd/system/
sudo systemctl enable instrumentald.service
sudo systemctl start instrumentald
```

### sysvinit (update-rc.d)

```sh
sudo cp /opt/instrumentald/lib/app/debian/instrumentald /etc/init.d/
sudo update-rc.d instrumentald defaults
sudo /etc/init.d/instrumentald start
```

### sysvinit (chkconfig)

```sh
sudo cp /opt/instrumentald/lib/app/rpm/instrumentald /etc/init.d/
sudo chkconfig --add instrumentald
sudo chkconfig instrumentald on
sudo service instrumentald start
```

# Chef

An example Chef cookbook for installing `instrumentald` is available in [`chef/instrumentald`](chef/instrumentald).

# Puppet

An example Puppet module for installing `instrumentald` is available in [`puppet/instrumentald`](puppet/instrumentald).
