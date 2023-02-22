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

variable "virtual_machines" {
  type = map(object({
    num_cpus                = number
    memory                  = number
    disk_label              = string
    domain                  = string
    ipv4_address            = string
    ipv4_netmask            = string
    ipv4_gateway            = string
    dns_server_list         = list(string)
  }))
}
