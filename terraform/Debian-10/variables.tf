#set of VM variables to authenticate to the vCenter
variable "vsphere_server" {
  description = "vSphere server"
  type        = string
}

variable "vsphere_user" {
  description = "vSphere username"
  type        = string
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
  sensitive   = true
}

variable "virtual_machine_template" {
  type        = map(string)
  description = "Configuration details for virtual machine template"

  default = {
    # default connection_type to SSH
    connection_type = "ssh"
    # username to connect to deployed virtual machines. defaults to "root"
    connection_user = "root"
    # default password to initially connect to deployed virtual machines. empty by default
    connection_password = "nY%aAYU4$6PtGYR8"
  }
}

variable "virtual_machines" {
  type = map(object({
    num_cpus                = number
    memory                  = number
    guest_id                = string
    disk_label              = string
    disk_size               = number
    domain                  = string
    ipv4_address            = string
    ipv4_netmask            = string
    ipv4_gateway            = string
    dns_server_list         = list(string)
    dns_suffix_list         = list(string)
  }))
}
