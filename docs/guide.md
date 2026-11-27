## Tofu OpenStack Config User Guide

Tofu OpenStack Config allows you to manage your Openstack config using Terraform.
This guide will provide you with example templates for available resources. A full
list of variables available for each resource can be found in [variables.tf](https://github.com/stackhpc/tofu-openstack-config/blob/main/variables.tf),
with a description and type.

It is recommended for easy readibility to separate your resources in `main.tf`
as follows:

```console
module "openstack" {
  source = "github.com/stackhpc/tofu-openstack-config//modules/openstack?ref=main"

  projects = local.project-config
  networks = local.network-config
  ...

}
```

The config for each resource can then be written into separate files, suggested
format is `<resource>-config.tf`, for example:

- project-config.tf
- network-config.tf
- router-config.tf

For information on how local values work, see this [opentofu.org website](https://opentofu.org/docs/language/values/locals/).
