#!/bin/bash

SKIP_TERRAFORM_INIT=0
SKIP_ANSIBLE=0
AUTO_APPROVE=0
APPLY_PARALLELISM=0
ENVIRONMENT_NAME=""
VAR_FILE=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -SkipTerraformInit|--skip-terraform-init) SKIP_TERRAFORM_INIT=1 ;;
        -SkipAnsible|--skip-ansible) SKIP_ANSIBLE=1 ;;
        -AutoApprove|--auto-approve) AUTO_APPROVE=1 ;;
        -ApplyParallelism|--apply-parallelism) APPLY_PARALLELISM="$2"; shift ;;
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
INVENTORY_PATH="$ANSIBLE_DIR/inventory.ini"
PLAYBOOK_PATH="$ANSIBLE_DIR/playbook.yml"
TFVARS_PATH=$(resolve_terraform_var_file "$REPO_ROOT" "$ENVIRONMENT_NAME" "$VAR_FILE" "false")
TERRAFORM_EXE=$(assert_resolved_command "terraform" "Install Terraform atau letakkan binary di lokasi yang didukung script." "/d/aplikasi/terraform/terraform.exe")

if [ "$SKIP_ANSIBLE" -eq 1 ]; then
    "$SCRIPT_DIR/check-prereqs.sh" -EnvironmentName "$ENVIRONMENT_NAME" -VarFile "$VAR_FILE"
else
    "$SCRIPT_DIR/check-prereqs.sh" -RequireAnsible -EnvironmentName "$ENVIRONMENT_NAME" -VarFile "$VAR_FILE"
fi

cd "$TERRAFORM_DIR"

if [ "$SKIP_TERRAFORM_INIT" -eq 0 ]; then
    echo "==> Running terraform init"
    "$TERRAFORM_EXE" init
fi

APPLY_ARGS=("apply")
RESOLVED_PARALLELISM=$APPLY_PARALLELISM

if [ "$RESOLVED_PARALLELISM" -le 0 ] && [ -f "$TFVARS_PATH" ]; then
    WORKLOAD_TYPE=$(grep -E '^\s*workload_type\s*=\s*' "$TFVARS_PATH" | head -n 1 | sed 's/.*"\(.*\)".*/\1/')
    if [ "$WORKLOAD_TYPE" = "lxc" ]; then
        RESOLVED_PARALLELISM=1
    fi
fi

if [ "$RESOLVED_PARALLELISM" -gt 0 ]; then
    APPLY_ARGS+=("-parallelism=$RESOLVED_PARALLELISM")
fi

if [ "$TFVARS_PATH" != "$TERRAFORM_DIR/terraform.tfvars" ]; then
    APPLY_ARGS+=("-var-file=$TFVARS_PATH")
fi

if [ "$AUTO_APPROVE" -eq 1 ]; then
    APPLY_ARGS+=("-auto-approve")
fi

echo "==> Running terraform ${APPLY_ARGS[*]}"
"$TERRAFORM_EXE" "${APPLY_ARGS[@]}"

cd "$REPO_ROOT"

echo "==> Checking generated Ansible inventory"
"$SCRIPT_DIR/check-prereqs.sh" -RequireInventory -EnvironmentName "$ENVIRONMENT_NAME" -VarFile "$VAR_FILE"

if [ "$SKIP_ANSIBLE" -eq 1 ]; then
    echo "==> SkipAnsible aktif. Flow berhenti setelah terraform apply."
    echo "Inventory tersedia di: $INVENTORY_PATH"
    exit 0
fi

WORKLOAD_TYPE=""
VM_STARTED=""

if [ -f "$TFVARS_PATH" ]; then
    WORKLOAD_TYPE=$(grep -E '^\s*workload_type\s*=\s*' "$TFVARS_PATH" | head -n 1 | sed 's/.*"\(.*\)".*/\1/')
    VM_STARTED=$(grep -E '^\s*vm_started\s*=\s*' "$TFVARS_PATH" | head -n 1 | sed -E 's/.*=\s*(true|false).*/\1/')
fi

if [ "$WORKLOAD_TYPE" = "vm" ] && [ "$VM_STARTED" = "false" ]; then
    echo "Error: Ansible diblokir untuk workload_type = \"vm\" dengan vm_started = false. Gunakan -SkipAnsible atau ubah vm_started = true."
    exit 1
fi

WSL_EXE=$(assert_wsl_command "ansible-playbook" "Install Ansible di distro WSL2 atau gunakan -SkipAnsible.")
ANSIBLE_DIR_WSL=$(convert_windows_path_to_wsl_path "$ANSIBLE_DIR")
INVENTORY_PATH_WSL=$(convert_windows_path_to_wsl_path "$INVENTORY_PATH")
PLAYBOOK_PATH_WSL=$(convert_windows_path_to_wsl_path "$PLAYBOOK_PATH")

if [ "$WSL_EXE" = "DIRECT_EXEC" ]; then
    echo "==> Running ansible-playbook natively on Linux/WSL"
    cd "$ANSIBLE_DIR"
    export ANSIBLE_HOST_KEY_CHECKING=False
    ansible-playbook -i "$INVENTORY_PATH" "$PLAYBOOK_PATH" --vault-password-file ~/.vault_pass
else
    BASH_COMMAND="cd $(quote_bash_literal "$ANSIBLE_DIR_WSL") && export ANSIBLE_HOST_KEY_CHECKING=False && ansible-playbook -i $(quote_bash_literal "$INVENTORY_PATH_WSL") $(quote_bash_literal "$PLAYBOOK_PATH_WSL") --vault-password-file ~/.vault_pass"
    echo "==> Running ansible-playbook via WSL"
    "$WSL_EXE" sh -lc "$BASH_COMMAND"
fi

echo "==> Selesai. Terraform dan Ansible berhasil dijalankan."
