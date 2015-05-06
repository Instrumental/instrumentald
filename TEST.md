# Testing Installation

You can test installation of `instrumental_tools` by running the [ServerSpec tests](test/integration/default/serverspec/). From the `chef` or `puppet` directories, run the following command:

```
bundle exec kitchen verify
```

to test installation and setup procedures for the `instrumental_tools` command. You must have [Vagrant](https://www.vagrantup.com/) installed; currently the KitchenCI integration is setup to use [VMWare Fusion](http://www.vmware.com/products/fusion) and the [VMWare Fusion Vagrant provider](https://www.vagrantup.com/vmware); you can configure a separate provider for your specific setup by change the `provider` flag in the `.kitchen.yml` file for your particular setup.
