#!/bin/bash

# deploy-k3s.sh
# Automasi pemasangan cluster K3s dan ArgoCD via Ansible

SCRIPT_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
source "$SCRIPT_DIR/common.sh"

REPO_ROOT=$(dirname "$SCRIPT_DIR")
ANSIBLE_DIR="$REPO_ROOT/ansible"
INVENTORY_PATH="$ANSIBLE_DIR/inventory.ini"
PLAYBOOK_PATH="$ANSIBLE_DIR/k3s.yml"

echo "==> Validating K3s prerequisites"
assert_path_exists "$INVENTORY_PATH" "Ansible Inventory (Jalankan Terraform apply terlebih dahulu)"
assert_path_exists "$PLAYBOOK_PATH" "Ansible Playbook k3s.yml"

WSL_EXE=$(assert_wsl_command "ansible-playbook" "Install Ansible di distro WSL2 atau gunakan flow tanpa Ansible.")

echo "==> Running K3s and ArgoCD installation via Ansible"

if [ "$WSL_EXE" = "DIRECT_EXEC" ]; then
    echo "==> Running ansible-playbook natively on Linux/WSL"
    cd "$ANSIBLE_DIR"
    export ANSIBLE_HOST_KEY_CHECKING=False
    ansible-playbook -i "$INVENTORY_PATH" "$PLAYBOOK_PATH" --vault-password-file ~/.vault_pass
else
    # Untuk eksekusi dari Git Bash Windows
    ANSIBLE_DIR_WSL=$(convert_windows_path_to_wsl_path "$ANSIBLE_DIR")
    INVENTORY_PATH_WSL=$(convert_windows_path_to_wsl_path "$INVENTORY_PATH")
    PLAYBOOK_PATH_WSL=$(convert_windows_path_to_wsl_path "$PLAYBOOK_PATH")
    
    BASH_COMMAND="cd $(quote_bash_literal "$ANSIBLE_DIR_WSL") && export ANSIBLE_HOST_KEY_CHECKING=False && ansible-playbook -i $(quote_bash_literal "$INVENTORY_PATH_WSL") $(quote_bash_literal "$PLAYBOOK_PATH_WSL") --vault-password-file ~/.vault_pass"
    echo "==> Running ansible-playbook via WSL"
    "$WSL_EXE" sh -lc "$BASH_COMMAND"
fi

echo "==> Selesai. K3s dan ArgoCD berhasil di-deploy."
if [ -f "$ANSIBLE_DIR/argocd-admin-password.txt" ]; then
    echo "==> Password admin ArgoCD:"
    cat "$ANSIBLE_DIR/argocd-admin-password.txt"
fi
