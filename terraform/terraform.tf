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
  // Configured through the OS_CLOUD variable
  alias = "ovh"
}

provider "ovh" {
  endpoint           = "ovh-eu"
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}
