# tofu-openstack-config

An OpenTofu module and tooling for configuring an existing OpenStack cloud,
currently supporting defining projects, groups, users, role assignments, flavors and
RBAC'd networks. See below for more details. Tooling is also provided to generate
OpenTofu configurations from an existing cloud.

It is intended as an alternative to the Ansible project [stackhpc/openstack-config](https://github.com/stackhpc/openstack-config/),
with the aim of providing significantly better performance for large configurations
and better idempotency.

## Example module usage

To use the functionality here to define configuration for a cloud, create
an OpenTofu configuration including a module block referencing it. E.g.:

```hcl
# main.hcl:

module "openstack" {

  # The version here should be changed to the current release:
  source = "github.com/stackhpc/tofu-openstack-config//modules/openstack?ref=main"

  projects = {
    test = {
      description = "test project"
      compute_quota = {
        instances = 20
        cores     = 200
        ram       = 512000
      }
    }
  }
}
```

To install this module into your project, run:
```shell
tofu init
```

OpenStack credentials should be provided as usual (e.g. via a `clouds.yaml` file
with `OS_CLIENT_CONFIG_FILE` and `OS_CLOUD` set). Admin credentials are required
for most uses of this module.

The resources defined in your configuration can then be created using:
```shell
tofu apply
```

For user guide see [docs/guide.md](docs/guide.md). The `docs/` directory contains
information and examples for all supported resources.

For more comprehensive examples see the `examples/` directory. The example
`arcus` demonstrates how to use variables and the [merge function](https://opentofu.org/docs/language/functions/merge/)
to minimise repeated configuration.

## Functionality

See the module's [variables.tf](./variables.tf) for full details of inputs. Apart
from a few exceptions noted there, the module generally only handles resources
defined as its inputs. E.g. when defining role assignments via the `role_assignments`
input, these can only reference projects defined in the `projects` input.

By default, OpenTofu [limits](https://opentofu.org/docs/cli/commands/apply/#apply-options)
the number of concurrent operations to 10. This means that for example only API
calls will be made simultaneously. For large configurations it may be helpful
to raise this by using the `-parellelism` argument to `tofu apply.` This can
be set as a default in your shell using e.g.:

```shell
export TF_CLI_ARGS_apply="-parallelism=25"
```

### Comparison to stackhpc/openstack-config

This section provides an initial comparison of functionality vs:
- https://github.com/stackhpc/openstack-config/blob/main/etc/openstack-config/openstack-config.yml
- https://github.com/stackhpc/ansible-collection-openstack/tree/main/roles
Note this is not currently complete either in breadth or depth!

In the "Supported?" column:
- `Yes` indicates broadly-equivalent functionality is available
- `New` indicates `stackhpc/openstack-config` does not support this

The "Import?" column refers to support for [importing existing openstack configuration](#importing-existing-openstack-configurations) below.

| Feature           | Supported? | Import?  | Comments |
| ----------------- | ---------- | -------- | -------- |
| Domains           | No         | N/A      | Only the default domain is used |
| Projects          | Yes        | Yes      | Keypairs not supported |
| Groups            | Yes        | Yes      | |
| Users             | Yes        | Yes      | |
| Role assignments  | New        | Yes      | Only groups (not users) can be assigned roles |
| Networks          | Yes        | No       | |
| Routers           | Yes        | No       | |
| Security groups   | No         | N/A      | |
| Network RBAC      | Yes        | No       | |
| Flavors           | Yes        | Yes      | |
| Host aggregates   | No         | N/A      | |
| Images            | Yes        | No       | Does not support local_file_path for image upload |
| Image elements    | No         | N/A      | Considered out of scope |
| Ratings           | No         | N/A      | |


## Current Issues

This section notes some issues hit during testing with `examples/arcus/`.

During `tofu apply`:

```
│ Error: Provider produced inconsistent result after apply
│
│ When applying changes to module.roleB.openstack_identity_role_assignment_v3.A, provider "provider[\"registry.opentofu.org/hashicorp/openstack\"]" produced an unexpected new value: root object was present, but now absent.
│
│ This is a bug in the provider, which should be reported in the provider's own issue tracker.
```
But reapplying fixed it ...

Also not idempotent:

```
  # module.openstack.module.projects["sb-test-1"].openstack_blockstorage_quotaset_v3.project will be updated in-place
  ~ resource "openstack_blockstorage_quotaset_v3" "project" {
        id                   = "75dc3b8cb1324ea6a899c8281b9ff84b/RegionOne"
      ~ volume_type_quota    = {
          - "gigabytes___DEFAULT__"                          = "-1" -> null
          - "gigabytes_arcus-staging-ceph01-rbd"             = "-1" -> null
          - "gigabytes_arcus-staging-ceph01-rbd-multiattach" = "-1" -> null
          - "snapshots___DEFAULT__"                          = "-1" -> null
          - "snapshots_arcus-staging-ceph01-rbd"             = "-1" -> null
          - "snapshots_arcus-staging-ceph01-rbd-multiattach" = "-1" -> null
          - "volumes___DEFAULT__"                            = "-1" -> null
          - "volumes_arcus-staging-ceph01-rbd-multiattach"   = "-1" -> null
            # (1 unchanged element hidden)
        }
        # (9 unchanged attributes hidden)
    }
```

During `tofu apply`:
```
 Error: Error unassigning openstack_identity_role_assignment_v3 ...: Successfully re-authenticated, but got error executing request: Expected HTTP response code [204] when accessing [DELETE ..., but got 401 instead: {"error":{"code":401,"message":"The request you have made requires authentication.","title":"Unauthorized"}}
 ```

worked on 3rd attempt.

Does not appear to be fixable with `depends_on`, may be a bug in the underlying provider?

## Importing existing OpenStack configurations
This repository contains some additional Python tooling which can query an
existing OpenStack cloud and define configurations which represent it.

### Setup

Create a venv in your project directory:

```shell
python3 -m venv venv
. venv/bin/activate
pip install -U pip
```

Then install the tooling, changing the version as necessary:

```shell
pip install git+https://github.com/stackhpc/tofu-openstack-config@main
```

### Usage

With the venv activated and OpenStack credentials available as normal, run

```shell
tofu-os-cfg
```

This will query OpenStack and generate:
- `main.tf` - an example configuration using this module
- `imports.tf` - [import blocks](https://opentofu.org/docs/language/import/)
linking the above configuration to the cloud resources.

Various options can be used to limit which resources are inspected, run
`tofu-os-cfg --help` to see them.

By default the generated module path will depend on pip-installed package version.

The generated files should be reviewed and if necessary, modified. Note not all
features currently support migration.

To then actually import these resources into the OpenTofu state run:

```shell
tofu init # if necessary
tofu apply
```

noting that the plan should indicate resources will be imported.

The import blocks in the `imports.tf` file are idempotent; once the configuration
has been "applied" to import them, this file may be deleted, left in place and/or
committed, it does not matter.

### Development

- Create a project directory with a venv.
- Clone the repo (either inside or outside the project directory), then with the
  venv run `pip install -e path_to_repo`.
- Changes to the `src/` files are picked up when running `tofu-os-cfg`.
- Note that the `--output` argument can be used to determine where files are
  generated.

## VAST Support

See [docs/vast.md](docs/vast.md).
