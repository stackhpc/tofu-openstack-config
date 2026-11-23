resource "openstack_sharedfilesystem_sharetype_v2" "sharetypes" {
  for_each    = var.sharetypes
  name        = each.value.project_name != null ? openstack_identity_project_v3.project[each.value.project_name].id : each.key
  description = each.value.description
  is_public   = each.value.is_public
  extra_specs = { for k, v in each.value.extra_specs : k => tostring(v) }
}

resource "openstack_sharedfilesystem_sharetype_access_v2" "sharetypes_access" {
    for_each = var.sharetypes_access

    share_type_id = each.value.sharetype_name != null ? openstack_sharedfilesystem_sharetype_v2.sharetypes[each.value.sharetype_name].id : each.value.share_type_id
    project_id    = each.value.project != null ? openstack_identity_project_v3.project[each.value.project].id : each.value.project_id
}
