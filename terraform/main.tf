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

locals {
  workload_is_vm      = var.workload_type == "vm"
  workload_is_lxc     = var.workload_type == "lxc"
  effective_ansible_user = var.ansible_user != null ? var.ansible_user : (
    local.workload_is_lxc ? "root" : var.vm_user
  )
  normalized_vms = {
    for name, vm in var.vms : name => {
      vm_id     = vm.vm_id
      vm_ip     = vm.vm_ip
      role      = coalesce(try(vm.role, null), var.vm_defaults.role)
      cpu_cores = coalesce(try(vm.cpu_cores, null), var.vm_defaults.cpu_cores)
      memory    = coalesce(try(vm.memory, null), var.vm_defaults.memory)
      disk_size = coalesce(try(vm.disk_size, null), var.vm_defaults.disk_size)
      tags = distinct(concat(
        var.default_tags,
        try(vm.tags, []),
        compact([coalesce(try(vm.role, null), var.vm_defaults.role)]),
        local.workload_is_lxc ? ["lxc"] : []
      ))
    }
  }
  ansible_targets = var.vm_started ? local.normalized_vms : {}
  ansible_roles   = distinct([for _, vm in local.ansible_targets : vm.role if vm.role != null && trimspace(vm.role) != ""])
}

resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  for_each = local.workload_is_vm ? local.normalized_vms : {}

  name        = each.key
  description = each.value.role != null ? "VM managed by Terraform and configured by Ansible (${each.value.role})" : "VM managed by Terraform and configured by Ansible"
  tags        = each.value.tags

  node_name = var.proxmox_node
  vm_id     = each.value.vm_id

  started         = var.vm_started
  stop_on_destroy = true

  agent {
    enabled = false
  }

  cpu {
    cores = each.value.cpu_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = var.vm_datastore_id
    import_from  = var.cloud_image_file_id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = each.value.disk_size
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  initialization {
    datastore_id = var.vm_datastore_id

    dns {
      servers = var.dns_servers
    }

    ip_config {
      ipv4 {
        address = "${each.value.vm_ip}/${var.vm_cidr}"
        gateway = var.vm_gateway
      }
    }

    user_account {
      username = var.vm_user
      keys     = [trimspace(file(pathexpand(var.ssh_public_key_path)))]
    }
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  lifecycle {
    precondition {
      condition     = var.cloud_image_file_id != null && trimspace(var.cloud_image_file_id) != ""
      error_message = "cloud_image_file_id wajib diisi saat workload_type = \"vm\"."
    }
  }
}

resource "proxmox_virtual_environment_container" "ubuntu_lxc" {
  for_each = local.workload_is_lxc ? local.normalized_vms : {}

  description = each.value.role != null ? "LXC managed by Terraform and configured by Ansible (${each.value.role})" : "LXC managed by Terraform and configured by Ansible"
  tags        = each.value.tags

  node_name    = var.proxmox_node
  vm_id        = each.value.vm_id
  started      = var.vm_started
  unprivileged = var.lxc_unprivileged

  features {
    nesting = var.lxc_nesting
  }

  cpu {
    cores = each.value.cpu_cores
  }

  memory {
    dedicated = each.value.memory
    swap      = var.lxc_swap
  }

  initialization {
    hostname = each.key

    dns {
      servers = var.dns_servers
    }

    ip_config {
      ipv4 {
        address = "${each.value.vm_ip}/${var.vm_cidr}"
        gateway = var.vm_gateway
      }
    }

    user_account {
      keys = [trimspace(file(pathexpand(var.ssh_public_key_path)))]
    }
  }

  network_interface {
    name   = var.lxc_network_interface_name
    bridge = var.network_bridge
  }

  disk {
    datastore_id = var.vm_datastore_id
    size         = each.value.disk_size
  }

  operating_system {
    template_file_id = var.container_template_file_id
    type             = var.container_operating_system_type
  }

  lifecycle {
    precondition {
      condition     = var.container_template_file_id != null && trimspace(var.container_template_file_id) != ""
      error_message = "container_template_file_id wajib diisi saat workload_type = \"lxc\"."
    }
  }
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"

  content = templatefile("${path.module}/inventory.tpl", {
    vms     = local.ansible_targets
    roles   = local.ansible_roles
    vm_user = local.effective_ansible_user
    ssh_key = var.ssh_private_key_path
  })

  depends_on = [
    proxmox_virtual_environment_vm.ubuntu_vm,
    proxmox_virtual_environment_container.ubuntu_lxc
  ]
}
