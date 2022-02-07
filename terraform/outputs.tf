output "instance_ipv4" {
  description = "Alpine instance IP address"
  value       = openstack_compute_instance_v2.alpine.network.0.fixed_ip_v4
}
