# TODO: check keys exist
# TODO: check is_public is false if projects defined

locals {
  flavor_projects = {
    for fp in flatten(
      [
        for flavor_name, flavor in var.flavors : [
          for project in flavor.projects : {
            flavor_name  = flavor_name
            project_name = project
          }
        ]
      ]
    ) : "${fp.flavor_name}:${fp.project_name}" => fp
  }
}

resource "openstack_compute_flavor_v2" "flavor" {

  for_each = var.flavors

  name         = each.key
  ram          = each.value.ram
  vcpus        = each.value.vcpus
  disk         = each.value.disk
  ephemeral    = lookup(each.value, "ephemeral", null)
  swap         = lookup(each.value, "swap", null)
  rx_tx_factor = lookup(each.value, "rx_tx_factor", null)
  is_public    = length(each.value.projects) > 0 ? false : each.value.is_public # needed to replicate cli/Ansible behaviour
  flavor_id    = lookup(each.value, "flavor_id", null)
  extra_specs  = lookup(each.value, "extra_specs", null)

}

resource "openstack_compute_flavor_access_v2" "flavor_access" {
  # NB: can only map to projects we are defining!
  for_each = local.flavor_projects

  tenant_id = openstack_identity_project_v3.project[each.value.project_name].id
  flavor_id = openstack_compute_flavor_v2.flavor[each.value.flavor_name].id
}
