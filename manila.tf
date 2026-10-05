resource "openstack_sharedfilesystem_sharetype_v2" "sharetypes" {
    for_each = var.sharetypes

    name = each.key

    description = lookup(each.value, "description", null)
    is_public  = lookup(each.value, "is_public", true)

    extra_specs = merge(
        { for k, v in each.value.extra_specs: k => tostring(v) if k != "vast_vippool_name"},
        contains(keys(each.value.extra_specs), "vast_vippool_name") ? {
        "vast:vippool_name" = try(vastdata_vip_pool.vippools[each.value.extra_specs.vast_vippool_name].name, null)
        } : {}
    )
}

resource "openstack_sharedfilesystem_sharetype_access_v2" "sharetypes_access" {
    for_each = var.sharetypes_access

    share_type_id = each.value.sharetype_name != null ? openstack_sharedfilesystem_sharetype_v2.sharetypes[each.value.sharetype_name].id : each.value.share_type_id
    project_id    = each.value.project != null ? openstack_identity_project_v3.project[each.value.project].id : each.value.project_id
}
