output "vm_list" {
  value = {
    for name, vm in module.workloads.normalized_vms : name => {
      ip    = vm.vm_ip
      role  = vm.role
      tags  = vm.tags
      vm_id = vm.vm_id
      ssh   = var.vm_started ? "ssh ${module.workloads.effective_ansible_user}@${vm.vm_ip}" : "not available while vm_started = false"
    }
  }
}

output "ansible_inventory_path" {
  value = "${path.module}/../ansible/inventory.ini"
}

output "workload_type" {
  value = var.workload_type
}
