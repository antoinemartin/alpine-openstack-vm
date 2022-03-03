// resource "openstack_compute_keypair_v2" "alpine" {
//   provider   = openstack.ovh
//   name       = "alpine"
// }

// Create new image from current
resource "openstack_images_image_v2" "alpine" {
  provider         = openstack.ovh
  name             = "alpine-openstack"
  local_file_path  = "../alpine-openstack.qcow2"
  container_format = "bare"
  disk_format      = "qcow2"
  visibility       = "private"

  // TODO: Put information about the build here
  //   properties = {
  //     key = "value"
  //   }
}

// Create instance from the image
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

// Create DNS entry. Cannot be used for testing because of propagation times.
resource "ovh_domain_zone_record" "alpine" {
  zone      = var.instance_dns_zone
  subdomain = var.instance_name
  fieldtype = "A"
  ttl       = "60"
  target    = openstack_compute_instance_v2.alpine.network.0.fixed_ip_v4
}

// Wait for SSH to be available on resource
resource "null_resource" "waitssh" {
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = openstack_compute_instance_v2.alpine.network.0.fixed_ip_v4
      user        = "root"
      private_key = var.instance_key
      timeout     = "1m"
    }

    inline = ["echo 'connected!'"]
  }

}
