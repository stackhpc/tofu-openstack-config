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
