resource "openstack_identity_group_v3" "group" {
    for_each = var.groups
    name        = each.key
    description = each.value
}
