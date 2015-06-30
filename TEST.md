# Testing Installation

You can test installation of `instrumental_tools` by running the [ServerSpec tests](test/integration/default/serverspec/). From the `chef` or `puppet` directories, run the following command:

```
bundle exec kitchen verify
```

to test installation and setup procedures for the `instrumental_tools` command. You must have [Vagrant](https://www.vagrantup.com/) installed; currently the KitchenCI integration is setup to use [VMWare Fusion](http://www.vmware.com/products/fusion) and the [VMWare Fusion Vagrant provider](https://www.vagrantup.com/vmware); you can configure a separate provider for your specific setup by change the `provider` flag in the `.kitchen.yml` file for your particular setup.

## Windows

Ensure you have the `winrm` vagrant plugin installed.

```
vagrant plugin install vagrant-winrm
```


To ensure you have a Windows Vagrant image, perform the following steps in a separate directory to build a Windows evaluation image:

```
git clone https://github.com/boxcutter/windows.git
cd windows
make virtualbox/eval-win2012r2-standard
vagrant box add windows-2012r2 ./box/virtualbox/eval-win2012r2-standard-nocm-1.0.4.box
```
