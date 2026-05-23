variable "workload_type" {
  type = string
}

variable "default_tags" {
  type = list(string)
}

variable "vm_started" {
  type = bool
}

variable "ansible_user" {
  type     = string
  nullable = true
  default  = null
}

variable "vm_user" {
  type = string
}

variable "vms" {
  type = map(object({
    vm_id     = number
    vm_ip     = string
    role      = optional(string)
    tags      = optional(list(string), [])
    cpu_cores = optional(number)
    memory    = optional(number)
    disk_size = optional(number)
  }))
}

variable "vm_defaults" {
  type = object({
    role      = optional(string)
    cpu_cores = number
    memory    = number
    disk_size = number
  })
}

variable "proxmox_node" {
  type = string
}

variable "vm_datastore_id" {
  type = string
}

variable "network_bridge" {
  type = string
}

variable "vm_gateway" {
  type = string
}

variable "vm_cidr" {
  type = number
}

variable "dns_servers" {
  type = list(string)
}

variable "ssh_public_key_path" {
  type = string
}

variable "cloud_image_file_id" {
  type     = string
  nullable = true
  default  = null
}

variable "container_template_file_id" {
  type     = string
  nullable = true
  default  = null
}

variable "container_operating_system_type" {
  type = string
}

variable "lxc_unprivileged" {
  type = bool
}

variable "lxc_nesting" {
  type = bool
}

variable "lxc_swap" {
  type = number
}

variable "lxc_network_interface_name" {
  type = string
}
