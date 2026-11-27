
data "openstack_identity_role_v3" "role" {
  for_each = toset([for v in var.role_assignments: v.role])
  name = each.value
}

resource "openstack_identity_role_assignment_v3" "role_assign" {

    for_each = {
      for v in var.role_assignments : "${v.project}:${v.group}:${v.role}" => v
    }
    
    group_id    = openstack_identity_group_v3.group[each.value.group].id
    project_id = openstack_identity_project_v3.project[each.value.project].id
    role_id    = data.openstack_identity_role_v3.role[each.value.role].id
}
