terraform {
  required_providers {
    ignition = {
      source  = "community-terraform-providers/ignition"
      version = "~> 2.1.1"
    }
    template = {
      source = "hashicorp/template"
    }
    tls = {
      source = "hashicorp/tls"
    }
    vsphere = {
      source = "hashicorp/vsphere"
    }
  }
}

