variable "projects" {
  description = <<-EOT
    Map of projects. Keys are project name. Values are mappings with keys/values:
      description: Optional string
      compute_quota: mapping
      network_quota: mapping
      blockstorage_quota: mapping
    For keys/values for quotas see type declarations
  EOT
  type = map(
    object({
      description = optional(string)
      compute_quota = optional(
        object({
          key_pairs            = optional(number)
          ram                  = optional(number)
          cores                = optional(number)
          instances            = optional(number)
          server_groups        = optional(number)
          server_group_members = optional(number)
        })
      )
      blockstorage_quota = optional(
        object({
          volumes              = optional(number)
          snapshots            = optional(number)
          gigabytes            = optional(number)
          per_volume_gigabytes = optional(number)
          backups              = optional(number)
          backup_gigabytes     = optional(number)
          groups               = optional(number)
          volume_type_quota    = optional(map(any)) # TODO: improve!
        })
      )
      network_quota = optional(
        object({
          floatingip          = optional(number)
          network             = optional(number)
          port                = optional(number)
          rbac_policy         = optional(number)
          router              = optional(number)
          security_group      = optional(number)
          security_group_rule = optional(number)
          subnet              = optional(number)
          subnetpool          = optional(number)
        })
      )
    })
  )
  default = {}
}

variable "groups" {
  description = "Map of groups. Keys are group names, values are group descriptions"
  type        = map(string)
  default     = {}
}

variable "users" {
  description = <<-EOT
    Map of users. Keys are user names. Values are mappings with keys/values:
      description: Optional string
      email: Optional string
      groups: Optional list of group name strings, must be keys from var.groups
      password: Optional string **WARNING** this will be saved in state
      default_project: Optional string with name of default project, must be key in var.projects
    If password is provided, this must be changed on first use.
  EOT
  type    = map(
    object({
      description = optional(string)
      email = optional(string)
      groups = optional(list(string))
      password = optional(string)
      default_project = optional(string)
    })
  )
  default = {}
}

variable "role_assignments" {
  description = <<-EOT
    List of role assignments. Elements are maps with keys/values:
      role: string name of pre-existing role
      group: string group name, a key from var.groups
      project: string project name, a key from var.projects
    Note an error will occur if elements are not unique.
  EOT
  type = list(
    object({
      role    = string
      group   = string
      project = string
    })
  )
  default = []
}

variable "network_rbac" {
  description = <<-EOT
    List of network RBAC configurations. Elements are maps with keys/values:
      network: string name of pre-existing network
      projects: list of project name strings, must be keys from var.projects
      access: string access type, "access_as_external" or "access_as_shared"
  EOT
  type = list(
    object({
      network  = string
      projects = list(string)
      access   = string
    })
  )
  validation {
    condition     = alltrue([for v in var.network_rbac : contains(["access_as_external", "access_as_shared"], v.access)])
    error_message = "Value for access must be access_as_external or access_as_shared"
  }
  default = []
}

variable "networks" {
  description = <<-EOT
    Map of networks. Keys are unique tofu resource names. Elements are maps with keys/values:
      name: Required string, openstack name of network
      region: Optional string
      shared: Optional bool, default false
      external: Optional bool, default false
      admin_state_up: Optional bool, default false
      project: Optional string openstack project name, overrides tenant_id
      tenant_id: Optional string, openstack project ID
      mtu: Optional number
      port_security_enabled: Optional bool, default false
      tags: Optional list
      segments: Optional list of objects -
        physical_network: Optional string
        network_type: Optional string
        segmentation_id: Optional number

      subnets: Optional map -
        key: Required string, tofu resource name
        name: Required string, openstack name
        region: Optional string
        cidr: Optional string
        ip_version: Optional number, default 4
        gateway_ip: Optional string
        enable_dhcp: Optional bool, default true
        dns_nameservers: Optional list
        dns_publish_fixed_ip: Optional bool, default false
        service_types: Optional list
        subnetpool_id: Optional string
        prefix_length: Optional number
        no_gateway: Optional bool
        tags: Optional list
        allocation_pool: Optional list of objects -
          start: Required string
          end: Required string
  EOT
  type = map(
    object({
      name                  = string
      region                = optional(string)
      shared                = optional(bool, false)
      external              = optional(bool, false)
      admin_state_up        = optional(bool)
      project               = optional(string)
      tenant_id             = optional(string)
      mtu                   = optional(number)
      port_security_enabled = optional(bool, true)
      tags                  = optional(list(string), [])

      segments = optional(
        list(object({
        physical_network = optional(string)
        network_type     = optional(string)
        segmentation_id  = optional(number)
        })), []
      )

      subnets = optional (map(object({
        name                 = string
        region               = optional(string)
        cidr                 = optional(string)
        ip_version           = optional(number, 4)
        gateway_ip           = optional(string)
        enable_dhcp          = optional(bool, true)
        dns_nameservers      = optional(list(string), [])
        dns_publish_fixed_ip = optional(bool, false)
        service_types        = optional(list(string), [])
        subnetpool_id        = optional(string)
        prefix_length        = optional(number)
        no_gateway           = optional(bool)
        tags                 = optional(list(string), [])

        allocation_pool = optional(
          list(object({
          start = string
          end   = string
          })), []
        )
      })), {} )
    })
  )

  validation {
    condition = alltrue(flatten([
      for network in values(var.networks) : [
        for subnet in values(lookup(network, "subnets", {})) :
        subnet.cidr != null || subnet.subnetpool_id != null
      ]
    ]))
    error_message = "Each subnet must specify either cidr or subnetpool_id."
  }

  default = {}
}


variable "routers" {
  description = <<-EOT
    Map of routers. Keys are unique tofu resource names. Elements are maps with keys/values:
      name: Required string, openstack name of router
      region: Optional string
      external_network:  Optional string, key in var.networks, overrides external_network_id
      external_network_id: Optional string, openstack network ID
      admin_state_up: Optional bool
      project: Optional string, tofu resource project name, overrides tenant_id
      tenant_id: Optional string, openstack project ID
      tags: Optional list
      external_fixed_ip: Optional list of maps -
        subnet: Optional string, tofu resource subnet name, overrides subnet_id
        subnet_id: Optional string, openstack subnet ID
        ip_address: Optional string

      interfaces: Optional list of maps -
        region: Optional string
        subnet: Optional string, key in var.network[network_key].subnets, overrides subnet_id
        subnet_id: Optional string, openstack subnet ID
        port_id: Optional string
        force_destroy: Optional bool, default false
  EOT

  type = map(
    object({
      name                = string
      region              = optional(string)
      external_network    = optional(string)
      external_network_id = optional(string)
      admin_state_up      = optional(bool)
      project             = optional(string)
      tenant_id           = optional(string)
      tags                = optional(list(string), [])

      external_fixed_ip = optional(
        list(object({
          subnet     = optional(string)
          subnet_id  = optional(string)
          ip_address = optional(string)
        })), []
      )

      interfaces = optional(
        list(object({
          region        = optional(string)
          subnet        = optional(string)
          subnet_id     = optional(string)
          port_id       = optional(string)
          force_destroy = optional(bool, false)
          })), []
      )
    })
  )
  default = {}
}

variable "flavors" {
  description = <<-EOT
        Mapping of flavor definitions. Key is flavor name, and must be quoted
        if it contains ".". Values are mappings with with keys/values:
            ram: Required integer
            vcpus: Required integer
            disk: Required integer
            ephemeral: Optional integer
            swap: Optional integer
            rx_tx_factor: Optional
            is_public: Optional bool, default true. If "projects" is non-empty
            this is ignored and set false
            flavor_id: Optional string
            extra_specs: Optional mapping
            projects: Optional list of project names to which flavor should be
            mapped (i.e. flavor only visible/usable from these projects). Project
            names must be keys from var.projects.
    EOT
  type = map(
    object({
      ram          = number
      vcpus        = number
      disk         = number
      ephemeral    = optional(number)
      swap         = optional(number)
      rx_tx_factor = optional(number)
      is_public    = optional(bool, true)
      flavor_id    = optional(string)
      extra_specs  = optional(map(string))
      projects     = optional(list(string), [])
    })
  )
  default = {}
}

variable "images"{
  description = <<-EOT
        Mapping of image definitions. Key is image name.
          container_format: Required string
          disk_format: Required string
          image_cache_path: Optional string
          image_source_url: Optional string
          image_id: Optional string
          min_disk_gb: Optional number, default 0.
          min_ram_mb: Optional number, default 0.
          protected: Optional bool, default false
          hidden: Optional bool, default false
          web_download: Optional bool, default false
          properties: Optional list of string
          visibility: Optional string
    EOT
  type = map(
    object({
      container_format = string
      disk_format      = string
      image_cache_path = optional(string)
      image_source_url = optional(string)
      image_id         = optional(string)
      min_disk_gb      = optional(number)
      min_ram_mb       = optional(number)
      protected        = optional(bool, false)
      hidden           = optional(bool, false)
      web_download     = optional(bool, false)
      properties       = optional(map(string))
      visibility       = optional(string)

    })
  )
  default = {}
}

# TODO: more outputs?
output "projects" {
  #value = {for k, v in openstack_identity_project_v3.project: k => v.id}
  value = openstack_identity_project_v3.project
}

output "groups" {
  #value = {for k, v in openstack_identity_group_v3.group: k => v.id}
  value = openstack_identity_group_v3.group
}

output "role_assignments" {
  value = openstack_identity_role_assignment_v3.role_assign
}

# output "debug" {
#     value = {for v in flatten([for rbac in var.network_rbac: [for project in rbac.projects: {rbac=rbac, project=project}]]): "${v.rbac.network}:${v.project}" => v}
# }

output "subnets" {
  value = {
    for k, v in openstack_networking_subnet_v2.subnets :
    k => {
      id         = v.id
      gateway_ip = v.gateway_ip
      cidr       = v.cidr
    }
  }
}

output "networks" {
  value = {
    for k, v in openstack_networking_network_v2.networks :
    k => {
      id = v.id
      segments = v.segments
    }
  }
}

output "routers" {
  value = {
    for k, v in openstack_networking_router_v2.routers :
    k => {
      id = v.id
    }
  }
}
