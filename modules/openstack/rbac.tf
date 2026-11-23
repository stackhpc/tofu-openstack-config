data "openstack_networking_network_v2" "network" {
  for_each = toset([for v in var.network_rbac : v.network])
  name     = each.value
}

resource "openstack_networking_rbac_policy_v2" "rbac" {

  for_each = {
    for v in flatten(
      [for rbac in var.network_rbac : [for project in rbac.projects : { rbac = rbac, project = project }]]
    ) : "${v.rbac.network}:${v.project}" => v
  }

  action        = each.value.rbac.access # access_as_external/access_as_shared
  object_id     = data.openstack_networking_network_v2.network[each.value.rbac.network].id
  object_type   = "network"
  target_tenant = openstack_identity_project_v3.project[each.value.project].id
}
