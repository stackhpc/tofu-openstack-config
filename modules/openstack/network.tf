resource "openstack_networking_network_v2" "networks" {
    for_each = var.networks

    name                  = each.value.name
    region                = lookup(each.value, "region", null)
    shared                = lookup(each.value, "shared", false)
    external              = lookup(each.value, "external", false)
    admin_state_up        = lookup(each.value, "admin_state_up", null)
    tenant_id             = (each.value.project != null ? openstack_identity_project_v3.project[each.value.project].id : each.value.tenant_id)
    mtu                   = lookup(each.value, "mtu", null)
    port_security_enabled = lookup(each.value, "port_security_enabled", true)
    tags                  = lookup(each.value, "tags", [])

    dynamic "segments" {
        for_each = lookup(each.value, "segments", [])
        content {
            physical_network = lookup(segments.value, "physical_network", null)
            network_type     = lookup(segments.value, "network_type", null)
            segmentation_id  = lookup(segments.value, "segmentation_id", null)
        }
    }
}

resource "openstack_networking_subnet_v2" "subnets" {
  for_each = merge([
    for network_key, network in var.networks : {
      for subnet_key, subnet in lookup(network, "subnets", {}) :
      subnet_key => {
        network = network_key
        subnet  = subnet
      }
    }
  ]...)

    name                 = each.value.subnet.name
    network_id           = openstack_networking_network_v2.networks[each.value.network].id
    region               = lookup(each.value.subnet, "region", null)
    cidr                 = lookup(each.value.subnet, "cidr", null)
    ip_version           = lookup(each.value.subnet, "ip_version", 4) #default can be 4 or 6
    tenant_id            = openstack_networking_network_v2.networks[each.value.network].tenant_id
    gateway_ip           = lookup(each.value.subnet, "gateway_ip", null)
    enable_dhcp          = lookup(each.value.subnet, "enable_dhcp", true)
    dns_nameservers      = lookup(each.value.subnet, "dns_nameservers", [])
    dns_publish_fixed_ip = lookup(each.value.subnet, "dns_publish_fixed_ip", false)
    service_types        = lookup(each.value.subnet, "service_types", [])
    subnetpool_id        = lookup(each.value.subnet, "subnetpool_id", null)
    prefix_length        = lookup(each.value.subnet, "prefix_length", null)
    no_gateway           = lookup(each.value.subnet, "no_gateway", null)
    tags                 = lookup(each.value.subnet, "tags", [])

    dynamic "allocation_pool" {
        for_each = lookup(each.value, "allocation_pool", [])
        content {
            start = allocation_pool.value.start
            end   = allocation_pool.value.end
        }
    }
}

resource "openstack_networking_router_v2" "routers" {
    for_each = var.routers

    name                = each.value.name
    region              = lookup(each.value, "region", null)
    external_network_id = (each.value.external_network != null ? openstack_networking_network_v2.networks[each.value.external_network].id : each.value.external_network_id)
    admin_state_up      = lookup(each.value, "admin_state_up", null)
    tenant_id           = (each.value.project != null ? openstack_identity_project_v3.project[each.value.project].id : each.value.tenant_id )
    tags                = lookup(each.value, "tags", [])

    dynamic "external_fixed_ip" {
        for_each = lookup(each.value, "external_fixed_ip", [])
        content {
          subnet_id  = (each.value.subnet != null ? openstack_networking_subnet_v2.subnets[each.value.subnet].id : each.value.subnet_id)
          ip_address = lookup(external_fixed_ip.value, "ip_address", null)
        }
    }
}

resource "openstack_networking_router_interface_v2" "interfaces" {
  for_each = merge([
    for router_key, router in var.routers : {
      for iface in lookup(router, "interfaces", []) :
      "interface-${router_key}-${coalesce(iface.subnet, iface.subnet_id, iface.port_id)}" => {
        router = router_key
        iface  = iface
      }
    }
  ]...)

  router_id     = openstack_networking_router_v2.routers[each.value.router].id
  region        = lookup(each.value.iface, "region", null)
  subnet_id     = (each.value.iface.subnet != null ? openstack_networking_subnet_v2.subnets[each.value.iface.subnet].id : each.value.iface.subnet_id)
  port_id       = lookup(each.value.iface, "port_id", null)
  force_destroy = lookup(each.value.iface, "force_destroy", false)
}

