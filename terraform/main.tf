// resource "openstack_compute_keypair_v2" "alpine" {
//   provider   = openstack.ovh
//   name       = "alpine"
// }

resource "openstack_images_image_v2" "alpine" {
  provider         = openstack.ovh
  name             = "alpine-openstack"
  local_file_path  = "../alpine-openstack.qcow2"
  container_format = "bare"
  disk_format      = "qcow2"
  visibility       = "private"

  //   properties = {
  //     key = "value"
  //   }
}

# Création d'une instance
resource "openstack_compute_instance_v2" "alpine" {
  name        = var.instance_name
  provider    = openstack.ovh
  image_id    = openstack_images_image_v2.alpine.id
  flavor_name = var.instance_flavor
  key_pair    = var.instance_key_name
  // key_pair    = openstack_compute_keypair_v2.alpine.name
  network {
    name = "Ext-Net"
  }
}

resource "ovh_domain_zone_record" "alpine" {
  zone      = var.instance_dns_zone
  subdomain = var.instance_name
  fieldtype = "A"
  ttl       = "60"
  target    = openstack_compute_instance_v2.alpine.network.0.fixed_ip_v4
}
