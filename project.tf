resource "openstack_identity_project_v3" "project" {
  for_each = var.projects

  name        = each.key
  description = each.value.description
}

resource "openstack_blockstorage_quotaset_v3" "project" {
  # Skip projects where quotas has no blockstorage keys, else fails with
  # {"code": 400, "message": "Invalid input for field/attribute quota_set. Value: {}. {} does not have enough properties"}
  for_each = {
    for name, proj in var.projects :
    name => proj
    if proj.blockstorage_quota != null
  }

  project_id = openstack_identity_project_v3.project[each.key].id

  # so need to set these to null if not required
  volumes              = lookup(each.value.blockstorage_quota, "volumes", null)
  snapshots            = lookup(each.value.blockstorage_quota, "snapshots", null)
  gigabytes            = lookup(each.value.blockstorage_quota, "gigabytes", null)
  per_volume_gigabytes = lookup(each.value.blockstorage_quota, "per_volume_gigabytes", null)
  backups              = lookup(each.value.blockstorage_quota, "backups", null)
  backup_gigabytes     = lookup(each.value.blockstorage_quota, "backup_gigabytes", null)
  groups               = lookup(each.value.blockstorage_quota, "groups", null)
  volume_type_quota    = lookup(each.value.blockstorage_quota, "volume_type_quota", null)
  # in above $TYPE is presumably result of `openstack volume type list -c Name`:
  #   volumes_$TYPE = 30
  #   gigabytes_$TYPE = 500
  #   snapshots_$TYPE = 10
  # }
}


resource "openstack_compute_quotaset_v2" "project" {
  for_each = {for name, proj in var.projects: name => proj if contains(keys(proj), "compute_quota")}

  project_id           = openstack_identity_project_v3.project[each.key].id
  key_pairs            = lookup(each.value.compute_quota, "key_pairs", null)
  ram                  = lookup(each.value.compute_quota, "ram", null)
  cores                = lookup(each.value.compute_quota, "cores", null)
  instances            = lookup(each.value.compute_quota, "instances", null)
  server_groups        = lookup(each.value.compute_quota, "server_groups", null)
  server_group_members = lookup(each.value.compute_quota, "server_group_members", null)
}

resource "openstack_networking_quota_v2" "project" {
  for_each = {for name, proj in var.projects: name => proj if contains(keys(proj), "network_quota")}

  project_id          = openstack_identity_project_v3.project[each.key].id
  floatingip          = lookup(each.value.network_quota, "floatingip", null)
  network             = lookup(each.value.network_quota, "network", null)
  port                = lookup(each.value.network_quota, "port", null)
  rbac_policy         = lookup(each.value.network_quota, "rbac_policy", null)
  router              = lookup(each.value.network_quota, "router", null)
  security_group      = lookup(each.value.network_quota, "security_group", null)
  security_group_rule = lookup(each.value.network_quota, "security_group_rule", null)
  subnet              = lookup(each.value.network_quota, "subnet", null)
  subnetpool          = lookup(each.value.network_quota, "subnetpool", null)
}

# TODO: add network
# TODO: What about manila? doens't appear to be a quota for that
