resource "openstack_images_image_v2" "image" {
    for_each = var.images

    name = each.key
    container_format = each.value.container_format
    disk_format      = each.value.disk_format
    image_cache_path = lookup(each.value, "image_cache_path", null)
    image_source_url = lookup(each.value, "image_source_url", null)
    image_id         = lookup(each.value, "image_id", null)
    min_disk_gb      = lookup(each.value, "min_disk_gb", null)
    min_ram_mb       = lookup(each.value, "min_ram_mb", null)
    protected        = lookup(each.value, "protected", false)
    hidden           = lookup(each.value, "hidden", false)
    web_download     = lookup(each.value, "web_download", false)
    properties       = lookup(each.value, "properties", null)
    visibility       = lookup(each.value, "visibility", null)
}