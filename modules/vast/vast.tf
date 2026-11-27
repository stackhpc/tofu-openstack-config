resource "vastdata_vip_pool" "vippools" {
  for_each = var.vippools

  name        = each.value.name != null ? (each.value.name) : (each.value.network != null ? format("openstack_vlan_%04d",
    one(var.networks[each.value.network].segments).segmentation_id)
    : each.key)
  vlan        = each.value.vlan != null ? (each.value.vlan) : one(var.networks[each.value.network].segments).segmentation_id
  role        = lookup(each.value, "role", null)
  subnet_cidr = lookup(each.value, "subnet_cidr", null)
  tenant_id   = (each.value.vast_tenant != null ? vastdata_tenant.vast_tenant[each.value.vast_tenant].id : each.value.tenant_id)
  ip_ranges   = each.value.ip_ranges != null ? (each.value.ip_ranges) : [
    for r in each.value.vip_ranges : [
      cidrhost(var.subnets[r.subnet].cidr, r.start),
      cidrhost(var.subnets[r.subnet].cidr, r.end)
    ]
  ]
}

resource "vastdata_tenant" "vast_tenant" {
  for_each = var.vast_tenants

  name                 = each.key
  allow_locked_users   = lookup(each.value, "allow_locked_users", null)
  allow_disabled_users = lookup(each.value, "allow_disabled_users", null)
  client_ip_ranges     = each.value.client_ip_ranges != null ? (each.value.client_ip_ranges) : [
    for p in each.value.client_ranges : [
      cidrhost(var.subnets[p.subnet].cidr, p.start),
      cidrhost(var.subnets[p.subnet].cidr, p.end)
    ]
  ]
}

resource "openstack_sharedfilesystem_sharetype_v2" "vast_sharetypes" {
  for_each    = var.vast_sharetypes
  name        = each.value.project_name != null ? var.projects[each.value.project_name].id : each.value.project_id
  description = each.value.description
  is_public   = each.value.is_public
  extra_specs = merge(
      { for k, v in each.value.extra_specs: k => tostring(v) if k != "vast_vippool_name"},
      contains(keys(each.value.extra_specs), "vast_vippool_name") ? {
      "vast:vippool_name" = try(vastdata_vip_pool.vippools[each.value.extra_specs.vast_vippool_name].name, null)
      } : {}
    )
}

resource "openstack_sharedfilesystem_sharetype_access_v2" "vast_sharetypes_access" {
    for_each = var.vast_sharetypes_access

    share_type_id = each.value.sharetype_name != null ? openstack_sharedfilesystem_sharetype_v2.vast_sharetypes[each.value.sharetype_name].id : each.value.share_type_id
    project_id    = each.value.project != null ? var.projects[each.value.project].id : each.value.project_id
}

