// provisioning_ssh_key creates a SSH key that will be used by the
// provisioners for each virtual machine to connect over SSH. This is a "fire
// and forget" key, and is deleted on the final step of the provisioner.
resource "tls_private_key" "provisioning_ssh_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

// root_user creates the user snippet for the "root" user for the
// virtual machine Ignition configuration. This allows us to push our
// provisioning key to the server.
data "ignition_user" "root_user" {
  name                = "root"
  password_hash       = var.rootuser_passwordhash
  ssh_authorized_keys = [tls_private_key.provisioning_ssh_key.public_key_openssh]
}

// core_user creates the user snippet for the "core" user for the
// virtual machine Ignition configuration. This is used to manage SSH keys for
// humans to connect to the virtual machines and manage them.
data "ignition_user" "core_user" {
  name                = "core"
  password_hash       = var.coreuser_passwordhash
  ssh_authorized_keys = var.management_ssh_keys
}

// service_user defines the user snippet for the service user for the
// virtual machine Ignition configuration. This prepares the user and the
// directory where the service binary will be uploaded to.
data "ignition_user" "service_user" {
  name     = var.service_user
  home_dir = var.service_directory
}

// service_unit_content renders a template with the systemd unit
// content for the service. This is fed into a systemd part of the Ignition
// configuration. Service directory and binary must exist previously in the 
// deployed template, otherwise the deployment will fail.
data "template_file" "service_unit_content" {
  template = file("${path.module}/files/ovf-example.service.tpl")

  vars = {
    service_directory  = var.service_directory
    server_binary_name = var.server_binary_name
    service_user       = var.service_user
  }
}

// service_unit defines the systemd unit that will manage the example service.
data "ignition_systemd_unit" "service_unit" {
  name    = "ovf-example.service"
  enabled = false
  content = data.template_file.service_unit_content.rendered
}

// virtual_machine_network_file, defines the network adapter configuration for
// each virtual machine. In this case, Fedora CoreOS uses NetworkManager, so we 
// will inject the resulting network file in the appropriate path. 
data "ignition_file" "virtual_machine_network_file" {
  count      = length(var.esxi_hosts)
  path       = "/etc/NetworkManager/system-connections/ens192.nmconnection"
  mode       = "384"
  content {
    content   = templatefile("${path.module}/files/ens192.network.tpl", {
      gateway = var.virtual_machine_gateway
      dns     = join("\n", var.virtual_machine_dns_servers)
      mask    = element(split("/", var.virtual_machine_network_address), 1)
      address = cidrhost(var.virtual_machine_network_address, var.virtual_machine_ip_address_start + count.index)
    })
  }
}

// virtual_machine_hostname_file defines the content of the system
// hostname file, in other words, it sets the hostname.
data "ignition_file" "virtual_machine_hostname_file" {
  count      = length(var.esxi_hosts)
  path       = "/etc/hostname"
  mode       = "420"

  content {
    content = "${var.virtual_machine_name_prefix}${count.index}.${var.virtual_machine_domain}}"
  }
}

// ignition_config creates the CoreOS Ignition config for use on the
// virtual machines.
data "ignition_config" "ignition_config" {
  count    = length(var.esxi_hosts)
  systemd  = [data.ignition_systemd_unit.service_unit.rendered]

  files = [
    data.ignition_file.virtual_machine_hostname_file.*.rendered[count.index],
    data.ignition_file.virtual_machine_network_file.*.rendered[count.index],
  ]

  users = [
    data.ignition_user.root_user.rendered,
    data.ignition_user.core_user.rendered,
    data.ignition_user.service_user.rendered,
  ]
}
