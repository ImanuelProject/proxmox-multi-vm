terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.70.0"
    }

    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_tls_insecure
}

module "workloads" {
  source = "./modules/proxmox-workloads"

  workload_type                   = var.workload_type
  default_tags                    = var.default_tags
  vm_started                      = var.vm_started
  ansible_user                    = var.ansible_user
  vm_user                         = var.vm_user
  vms                             = var.vms
  vm_defaults                     = var.vm_defaults
  proxmox_node                    = var.proxmox_node
  vm_datastore_id                 = var.vm_datastore_id
  network_bridge                  = var.network_bridge
  vm_gateway                      = var.vm_gateway
  vm_cidr                         = var.vm_cidr
  dns_servers                     = var.dns_servers
  ssh_public_key_path             = var.ssh_public_key_path
  ssh_public_key                  = var.ssh_public_key
  cloud_image_file_id             = var.cloud_image_file_id
  container_template_file_id      = var.container_template_file_id
  container_operating_system_type = var.container_operating_system_type
  lxc_unprivileged                = var.lxc_unprivileged
  lxc_nesting                     = var.lxc_nesting
  lxc_swap                        = var.lxc_swap
  lxc_network_interface_name      = var.lxc_network_interface_name
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"

  content = templatefile("${path.module}/inventory.tpl", {
    vms     = module.workloads.ansible_targets
    roles   = module.workloads.ansible_roles
    vm_user = module.workloads.effective_ansible_user
    ssh_key = var.ssh_private_key_path
  })

  depends_on = [module.workloads]
}
