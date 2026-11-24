## VAST Provider

To use the VAST resources, you'll need a `provider.tf` file in your `tofu/` dir containing
the required config:

```shell
terraform {
  required_providers {
    vastdata = {
      source = "vast-data/vastdata"
      version = "2.1.1"
    }
  }
}

provider "vastdata" {
  username        =    #string
  port            =    #number
  password        = var.vast_password #string
  host            =    #string
  skip_ssl_verify = true
}

variable "vast_password" {
  sensitive = true
}
```

Filling in the missing variables in the `provider "vastdata"` block. More infomation
on the vastdata provider config can be found in the [HashiCorp Terrafrom docs](https://registry.terraform.io/providers/vast-data/vastdata/latest/docs#example-usage).

> [!Caution]
> `vast_password` ends up in the state.

## Connecting VAST to OpenStack

To connect the VAST resource to OpenStack the VAST module needs to be used
alongside the OpenStack module.
In addition, `sharetypes` and `sharetypes_access` resources need to be used within
the VAST module. The `sharetypes` resource is required to have
`vast_vippool_name` defined in the `extra_specs` block to connect VAST.


Define the `openstack` and `vast` module block:

```shell
module "openstack" {
  source = "github.com/stackhpc/tofu-openstack-config//modules/openstack?ref=main"

  projects = ...
  networks = ...
  ...

}

module "vast" {
  source = "github.com/stackhpc/tofu-openstack-config//modules/vast?ref=main"

  # This gives the VAST modules the information it needs from the openstack module
  networks = module.openstack.networks
  subnets  = module.openstack.subnets
  projects = module.openstack.projects

  # VAST resources
  vast_tenants = ...
  vippools     = ...

  # openstack resources for VAST
  sharetypes        = ...
  sharetypes_access = ...

```

## VAST Vippools

To create a VAST vippool,

Example usage:

```console
vippools = {
    "client_manila" = {
      subnet_cidr = "24"
      network = "client_net_data:client"

      vast_tenant = "client"

      vip_ranges = [{
        subnet = "client_subnet_data:client"
        start  = 200
        end    = 249
      }]
    }

}
```

Arugment reference:
- `name` (Optional) string.
- `network` (Optional) string. Tofu resource network name.
- `vlan` (Optional) string
- `role` (Optional) string
- `subnet_cidr` (Optional) number
- `tenant_id` (Optional) string. VAST tenant id. Overriden by `vast_tenant`.
- `vast_tenant` (Optional) string. VAST tenant name. Overrides `tenant_id`.
- `vip_ranges` (Optional) list. Overriden by `ip_ranges`. Block supports:
    - `subnet` (Required) number. Tofu resource name of subnet.
    - `start` (Requied) number
    - `end` (Required) number
- `ip_ranges` (Optional) list. Overrides `vip_ranges`.


## VAST Tenants

To create a VAST tenant,

Example usage:

```console
vast_tenants = {
    "client" = {
      allow_locked_users = true
      allow_disabled_users = true

      client_ranges = [{
        subnet = "client_subnet_data:client"
        start = 2
        end = 149
      }]
    }
}
```

Argument reference:
- `allow_locked_users` (Optional) bool
- `allow_disabled_users` (Optional) bool
- `client_ranges` (Optional) list. Overriden by `client_ip_ranges`. Block supports:
    - `subnet` (Required) string. Tofu resource name of subnet.
    - `start` (Required) number
    - `end` (Required) number
- `client_ip_ranges` (Optional) list. Overrides `client_ranges`.

> [!WARNING]
> The resources:
> - `openstack_sharedfilesystem_sharetype_v2` used for `sharetypes`.
> - `openstack_sharedfilesystem_sharetype_access_v2` used for `sharetypes_access`.
>
> Are currently in development in opentofu. Therefore, they require
> a custom provider to use.


## Sharetypes for VAST

To create a sharetype,

Example usage:

```console
sharetypes = {
    client_sharetype = {
      name = "client-vast"
      description = "client - data"
      is_public = false

      extra_specs = {
        driver_handles_share_servers = false
        snapshot_support = true
        share_backend_name = "VAST"
        vippoolname = "client"
      }
    }
}
```

Argument reference:
- `description` (Optional) string
- `is_public` (Optional) bool, default true
- `extra_specs` (Required), block:
    - `driver_handles_share_servers` (Required) bool
    - `snapshot_support` (Optional) bool
    - `share_backend_name` (Optional) string
    - `vast_vippool_name` (Optional) string
    - can contain any additional vars if needed

## Sharetypes Access for VAST

For projects to have access to the correct sharetypes,  the `sharetypes_access`
resource is used.

To create a sharetype access,

Example usage:

```console
sharetypes-access = {
    "client_sharetype_access" = {
      sharetype_name = "client_sharetype"
      project = "client"
    }
}
```

Argument reference:
One is required:
- `sharetype_name` string
or
- `share_type_id` string
One is required:
- `project` string
or
- `project_id` string


