> [!WARNING]
> The resources:
> - `openstack_sharedfilesystem_sharetype_v2` used for `sharetypes`.
> - `openstack_sharedfilesystem_sharetype_access_v2` used for `sharetypes_access`.
>
> Are currently in development in opentofu. Therefore, they require
> a custom provider to use.


## Sharetypes

To create a sharetype,

Example usage:

```console
sharetypes = {
    client_sharetype = {
      name = "client"
      description = "client - data"
      is_public = false

      extra_specs = {
        driver_handles_share_servers = false
        snapshot_support = true
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
    - can contain any additional vars if needed

## Sharetypes Access

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
