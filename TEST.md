# Testing Installation

You can test installation of `instrumentald` by running the [ServerSpec tests](test/integration/default/serverspec/). From the `chef` or `puppet` directories, run the following command:

```
./script/test
```

to test installation and setup procedures for the `instrumentald` command. You must have [Vagrant](https://www.vagrantup.com/) installed; currently the KitchenCI integration is setup to use VirtualBox; you can configure a separate provider for your specific setup by change the `provider` flag in the `.kitchen.yml` file for your particular setup.

NOTE: Avoid using Vagrant 1.8.5. It has [a bug](https://github.com/mitchellh/vagrant/issues/7610) which will prevent the tests from running correctly.
