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
data "vsphere_virtual_machine" "esgi-deb-template" {
  name          = "ESGI_DEB11_Template"
  datacenter_id = data.vsphere_datacenter.dc.id
}

##########################################################################################
################################## Linux VM deployement ##################################
##########################################################################################

#Set VM parameteres
resource "vsphere_virtual_machine" "esgi-deb" {
  for_each = var.virtual_machines #Loop through the map of VMs

  name             = each.key
  num_cpus         = each.value.num_cpus
  memory           = each.value.memory
  guest_id         = each.value.guest_id
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  #Network interface section
  network_interface {
    network_id = data.vsphere_network.network.id
  }

  #Disk section
  disk {
    label            = each.value.disk_label
    thin_provisioned = true
    size             = each.value.disk_size
  }

  #VM customization section
  clone {
    template_uuid = data.vsphere_virtual_machine.esgi-deb-template.id
    #Linux_options are required section, while deploying Linux virtual machines
    customize {
      linux_options {
        host_name = each.key
        domain    = each.value.domain
      }
      network_interface {
        ipv4_address = each.value.ipv4_address
        ipv4_netmask = each.value.ipv4_netmask
      }
      #There are a global parameters and need to be outside linux_options section. If you put IP Gateway or DNS in the linux_options, these will not be added
      ipv4_gateway    = each.value.ipv4_gateway
      dns_server_list = each.value.dns_server_list
      dns_suffix_list = each.value.dns_suffix_list
    }
  }

  #Connection section will be used to connect to the VM and execute the commands
  connection {
    host     = each.value.ipv4_address
    type     = var.virtual_machine_template.connection_type
    user     = var.virtual_machine_template.connection_user
    password = var.virtual_machine_template.connection_password
  }

  #Provisioners section will be used to execute the commands on the VM
  provisioner "remote-exec" { #Remote-exec provisioner will execute the commands on the VM
    inline = [
      "apt update",                                                                  #Update the package list
      "apt install sudo htop curl unzip gpg -y",                                               #Install sudo, htop and curl
      "adduser --disabled-password --gecos '' ansible",                              #Create the user ansible
      "echo \"ansible  ALL=(ALL) NOPASSWD:ALL\" | sudo tee /etc/sudoers.d/username", #Add the user ansible to the sudoers file
      "mkdir /home/ansible/.ssh"                                                     #Create the .ssh directory
    ]
  }

  #Provisioner will copy the Ansible public key to the VM
  provisioner "file" {
    source      = "./VM_Config/authorized_keys"
    destination = "/home/ansible/.ssh/authorized_keys"
  }

  #Provisioner will execute the commands on the VM
  provisioner "remote-exec" { #Remote-exec provisioner will execute the commands on the VM
    inline = [
      "sudo chown -R ansible:ansible /home/ansible/.ssh",
      "sudo chmod 700 /home/ansible/.ssh",
      "sudo chmod 600 /home/ansible/.ssh/authorized_keys",
      "sudo usermod -aG sudo ansible"
    ]
  }
}

#Output section will display vsphere_virtual_machine.esgi-deb-grafana Name and IP Address
output "VMs_Name" {
  value = values(vsphere_virtual_machine.esgi-deb)[*].name
}

output "VMs_IP_Address" {
  value = values(vsphere_virtual_machine.esgi-deb)[*].clone.0.customize.0.network_interface.0.ipv4_address
}