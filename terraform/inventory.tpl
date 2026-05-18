[proxmox_vms]
%{ for name, vm in vms ~}
${name} ansible_host=${vm.vm_ip} ansible_user=${vm_user} ansible_ssh_private_key_file=${ssh_key}
%{ endfor ~}