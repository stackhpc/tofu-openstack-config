## Openstack variables
## note: module may not always be called 'openstack'

variable "networks" {   # module.openstack.networks
  type = map(object({ segments = list(object({ segmentation_id = number })) }))
  default = {}
}
variable "subnets" {    # module.openstack.subnets
  type = map(object({ cidr = string }))
  default = {}
}
variable "projects" {   # module.openstack.projects
  type = map(object({ id = string }))
  default = {}
}

## Vast variables

variable "vippools" {
  description = <<-EOT
    Map of vippools. Key is tofu resource name. Values are mappings with keys/values:
      name: Optional string, if not provided network is used to template name of format "openstack_vlan_<segmentation_id>"
      network: Optional string, tofu network resource name, used to template name and vlan if provided (using segmentation_id)
      vlan: Optional number
      role: Optional string
      subnet_cidr: Optional number
      tenant_id: Optional string, overridden by vast_tenant
      vast_tenant: Optional string, vast tenant name, overrides tenant_id
      vip_ranges: Optional list of objects -
        subnet: Required string, tofu subnet resource name
        start: Required number
        end: Required number
      ip_ranges: Optional list of strings.
  EOT
  type = map(
    object({
      name                  = optional(string)
      network               = optional(string)
      vlan                  = optional(number)
      role                  = optional(string)
      subnet_cidr           = optional(number)
      tenant_id             = optional(string)
      vast_tenant           = optional(string)
      # may need renaming
      vip_ranges            = optional(list(object({
        subnet = string
        start  = number
        end    = number
      })), [])
      ip_ranges             = optional(list(list(string)), null)
    })
  )
  default = {}
}

variable "vast_tenants" {
  description = <<-EOT
    Map of vast tenants. Key is tofu resource name. Values are mappings with keys/values:
      allow_locked_users: Optional bool
      allow_disabled_users: Optional bool
      client_ranges: Optional list of objects, overridden by client_ip_ranges
        subnet: Required string, tofu subnet resource name
        start: Required number
        end: Required number
      client_ip_ranges: Optional list, overrides client_ranges
  EOT
  type = map(
    object({
      allow_locked_users   = optional(bool, null)
      allow_disabled_users = optional(bool, null)
      # may need renaming
      client_ranges        = optional(list(object({
        subnet = string
        start  = number
        end    = number
      })), [])
      client_ip_ranges     = optional(list(list(string)), [])
    })
  )
  default = {}
}

## Manila sharetypes

variable "vast_sharetypes" {
  description = <<-EOT
    Mapping of sharetype definitions. Key is sharetype name. Values are mappings with keys/values:
      description: Optional string
      is_public: Optional bool, default true
      extra_specs: Required map
        driver_handles_share_servers: Required bool
        snapshot_support: Optional bool
        share_backend_name: Optional string
        vast_vippool_name: Optional string, tofu resource vippool name. Required for VAST.
  EOT
  type = map(
    object({
      project_name = optional(string)
      description  = optional(string)
      is_public    = optional(bool, true)

      extra_specs = map(any)
    })
  )

  validation {
    condition = alltrue([ for k, v in var.vast_sharetypes :
    contains(keys(v.extra_specs), "driver_handles_share_servers") &&
    can(tobool(v.extra_specs["driver_handles_share_servers"])) ])
    error_message = "Each entry's extra_specs must include driver_handles_share_servers (bool)."
  }

  validation {
    condition = alltrue([ for k, v in var.vast_sharetypes :
    !contains(keys(v.extra_specs), "vast_vippool_name") ||
    can(vastdata_vip_pool.vippools[v.extra_specs.vast_vippool_name].name)
    ])
    error_message = "vast_vippool_name given does not exsit"
  }

  default = {}
}

variable "vast_sharetypes_access" {
  description = <<-EOT
    Mappings of sharetype access definitions. Key is tofu sharetype access resource name. Values are mappings with keys/values:
    sharetype_name: Optional string, tofu sharetype resource name, overrides share_type_id
    share_type_id: Optional string, overridden by sharetype_name
    project: Optional string, tofu project resource name
    project_id: Optional string
  EOT
  type = map(
    object({
      sharetype_name = optional(string)
      share_type_id  = optional(string)
      project        = optional(string)
      project_id     = optional(string)
    })
  )
  default = {}
}

