[proxmox_vms]
%{ for name, vm in vms ~}
${name} ansible_host=${vm.vm_ip} ansible_user=${vm_user} ansible_ssh_private_key_file=${ssh_key}
%{ endfor ~}

%{ for role in roles ~}

[role_${role}]
%{ for name, vm in vms ~}
%{ if vm.role == role ~}
${name}
%{ endif ~}
%{ endfor ~}
%{ endfor ~}

[k3s_cluster:children]
k3s_master
k3s_worker

[k3s_master]
app-01

[k3s_worker]
app-02
web-01
