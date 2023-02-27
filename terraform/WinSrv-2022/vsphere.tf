#VMware vSphere Provider
provider "vsphere" {
  #Set of variables used to connect to the vCenter
  vsphere_server = var.vsphere_server
  user           = var.vsphere_user
  password       = var.vsphere_password

  #If you have a self-signed cert
  allow_unverified_ssl = true
}

#Name of the Datacenter in the vCenter
data "vsphere_datacenter" "dc" {
  name = "ProxFR Inc."
}
#Name of the Cluster in the vCenter
data "vsphere_compute_cluster" "cluster" {
  name          = "Cluster_Temp"
  datacenter_id = data.vsphere_datacenter.dc.id
}
#Name of the Datastore in the vCenter, where VM will be deployed
data "vsphere_datastore" "datastore" {
  name          = "DS-ESX2-SAS-SSD"
  datacenter_id = data.vsphere_datacenter.dc.id
}
#Name of the Portgroup in the vCenter, to which VM will be attached
data "vsphere_network" "network" {
  name          = "DPG-Trunk-100"
  datacenter_id = data.vsphere_datacenter.dc.id
}
#Name of the Templete in the vCenter, which will be used to the deployment
data "vsphere_virtual_machine" "winsrv2022" {
  name          = "ESGI_WS22_TEMPLATE"
  datacenter_id = data.vsphere_datacenter.dc.id
}

##########################################################################################
################################## esgi-win-debian-agent #################################
##########################################################################################

#Set VM parameteres
resource "vsphere_virtual_machine" "esgi-win" {

  # For each VM inside the virtual_machines map, create a VM resource
  for_each = var.virtual_machines

  name             = each.key
  num_cpus         = each.value.num_cpus
  memory           = each.value.memory
  guest_id         = data.vsphere_virtual_machine.winsrv2022.guest_id
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  scsi_type        = data.vsphere_virtual_machine.winsrv2022.scsi_type
  firmware         = "efi"

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    label            = each.value.disk_label
    thin_provisioned = true
    size             = data.vsphere_virtual_machine.winsrv2022.disks.0.size
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.winsrv2022.id

    customize {
      windows_options {
        computer_name = each.key
        time_zone     = 105 #Europe/Paris
        admin_password = "ansible" #Administator/ansible
      }
      network_interface {
        ipv4_address = each.value.ipv4_address
        ipv4_netmask = each.value.ipv4_netmask
        dns_domain   = each.value.domain
      }
      ipv4_gateway    = each.value.ipv4_gateway
      dns_server_list = each.value.dns_server_list
    }
  }
}

#Output section will display vsphere_virtual_machine.esgi-win-grafana Name and IP Address
output "VMs_Name" {
  value = values(vsphere_virtual_machine.esgi-win)[*].name
}

output "VMs_IP_Address" {
  value = values(vsphere_virtual_machine.esgi-win)[*].clone.0.customize.0.network_interface.0.ipv4_address
}
