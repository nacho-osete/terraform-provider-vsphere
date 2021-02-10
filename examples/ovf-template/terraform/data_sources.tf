// example_datacenter looks up the datacenter where all resources will be
// placed.
data "vsphere_datacenter" "datacenter" {
   name = var.datacenter
}

// example_hosts looks up the IDs for the hosts that will be used during
// datastore and distributed virtual switch creation, in addition to defining
// where each virtual machine will be placed. One virtual machine per host will
// be created.
data "vsphere_host" "hosts" {
  count         = length(var.esxi_hosts)
  name          = var.esxi_hosts[count.index]
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

// example_resource_pool looks up the resource pool to place the virtual machines in.
data "vsphere_resource_pool" "resource_pool" {
  name          = var.resource_pool
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

// example_datastore looks up the datastore to place the virtual machines in.
data "vsphere_datastore" "datastore" {
  name          = var.datastore_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

// example_network looks up the network to place the virtual machines in.
data "vsphere_network" "network" {
  name          = var.network_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

// example_template looks up the template to create the virtual machines as.
data "vsphere_virtual_machine" "template" {
  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}
