variable "instance_name" {
  type        = string
  description = "instance name"
}

variable "instance_dns_zone" {
  type        = string
  description = "DNS Zone (Domain suffix) on which to create the DNS entry"
}

variable "instance_flavor" {
  type        = string
  description = "Key name to use to spawn image"
  default     = "b2-7"
}

variable "instance_key_name" {
  type        = string
  description = "Key name to use to spawn image"
}

variable "openstack_username" {
  type        = string
  description = "Openstack username"
}

variable "openstack_password" {
  type        = string
  description = "Openstack password"
}

variable "openstack_region" {
  type        = string
  description = "Openstack region"
}



variable "openstack_tenant_id" {
  type        = string
  description = "Openstack tenant (Project) id"
}

variable "ovh_application_key" {
  type        = string
  description = "OVH API application key"
}

variable "ovh_application_secret" {
  type        = string
  description = "OVH API application secret"
}

variable "ovh_consumer_key" {
  type        = string
  description = "OVH API Consumer key"
}
