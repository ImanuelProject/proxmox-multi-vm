output "vm_list" {
  value = {
    for name, vm in var.vms : name => {
      ip    = vm.vm_ip
      vm_id = vm.vm_id
      ssh   = var.vm_started ? "ssh ${(var.ansible_user != null ? var.ansible_user : (var.workload_type == "lxc" ? "root" : var.vm_user))}@${vm.vm_ip}" : "not available while vm_started = false"
    }
  }
}

output "ansible_inventory_path" {
  value = "${path.module}/../ansible/inventory.ini"
}

output "workload_type" {
  value = var.workload_type
}
