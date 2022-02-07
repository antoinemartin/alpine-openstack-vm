terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "1.46.0"
    }
    ovh = {
      source  = "ovh/ovh"
      version = "0.16.0"
    }
  }
}

provider "openstack" {
  auth_url            = "https://auth.cloud.ovh.net/v3"
  user_name           = var.openstack_username
  password            = var.openstack_password
  project_domain_name = "Default"
  user_domain_name    = "Default"
  tenant_id           = var.openstack_tenant_id
  region              = var.openstack_region
  alias               = "ovh"
}

provider "ovh" {
  endpoint           = "ovh-eu"
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}
