#!/bin/bash

REQUIRE_ANSIBLE=0
REQUIRE_INVENTORY=0
ENVIRONMENT_NAME=""
VAR_FILE=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -RequireAnsible|--require-ansible) REQUIRE_ANSIBLE=1 ;;
        -RequireInventory|--require-inventory) REQUIRE_INVENTORY=1 ;;
        -EnvironmentName|--environment-name) ENVIRONMENT_NAME="$2"; shift ;;
        -VarFile|--var-file) VAR_FILE="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
source "$SCRIPT_DIR/common.sh"

REPO_ROOT=$(dirname "$SCRIPT_DIR")
TERRAFORM_DIR="$REPO_ROOT/terraform"
ANSIBLE_DIR="$REPO_ROOT/ansible"
TFVARS_PATH=$(resolve_terraform_var_file "$REPO_ROOT" "$ENVIRONMENT_NAME" "$VAR_FILE" "false")
PLAYBOOK_PATH="$ANSIBLE_DIR/playbook.yml"
INVENTORY_PATH="$ANSIBLE_DIR/inventory.ini"

echo "==> Validating local prerequisites"
assert_path_exists "$TERRAFORM_DIR" "Folder terraform"
assert_path_exists "$ANSIBLE_DIR" "Folder ansible"
assert_path_exists "$PLAYBOOK_PATH" "File playbook Ansible"
echo "==> Terraform var-file: $TFVARS_PATH"

if [ -z "$TF_VAR_proxmox_api_token" ]; then
    echo "Error: Environment variable 'TF_VAR_proxmox_api_token' belum diset. Contoh: export TF_VAR_proxmox_api_token=\"root@pam!terraform=your-token\""
    exit 1
fi

echo "==> TF_VAR_proxmox_api_token tersedia"

TERRAFORM_EXE=$(assert_resolved_command "terraform" "Install Terraform atau letakkan binary di lokasi yang didukung script." "/d/aplikasi/terraform/terraform.exe")
echo "==> Terraform found at: $TERRAFORM_EXE"

if [ "$REQUIRE_ANSIBLE" -eq 1 ]; then
    WSL_EXE=$(assert_wsl_command "ansible-playbook" "Install Ansible di distro WSL2 atau gunakan flow tanpa Ansible.")
    echo "==> WSL found at: $WSL_EXE"
    echo "==> ansible-playbook tersedia di WSL"
fi

if [ "$REQUIRE_INVENTORY" -eq 1 ]; then
    assert_path_exists "$INVENTORY_PATH" "Inventory Ansible hasil generate Terraform"
fi

echo "==> Prerequisite check selesai."
