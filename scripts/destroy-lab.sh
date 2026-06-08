#!/bin/bash

SKIP_TERRAFORM_INIT=0
AUTO_APPROVE=0
ENVIRONMENT_NAME=""
VAR_FILE=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -SkipTerraformInit|--skip-terraform-init) SKIP_TERRAFORM_INIT=1 ;;
        -AutoApprove|--auto-approve) AUTO_APPROVE=1 ;;
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
TFVARS_PATH=$(resolve_terraform_var_file "$REPO_ROOT" "$ENVIRONMENT_NAME" "$VAR_FILE" "false")
TERRAFORM_EXE=$(assert_resolved_command "terraform" "Install Terraform atau letakkan binary di lokasi yang didukung script." "/d/aplikasi/terraform/terraform.exe")

"$SCRIPT_DIR/check-prereqs.sh" -EnvironmentName "$ENVIRONMENT_NAME" -VarFile "$VAR_FILE"

cd "$TERRAFORM_DIR"

if [ "$SKIP_TERRAFORM_INIT" -eq 0 ]; then
    echo "==> Running terraform init"
    "$TERRAFORM_EXE" init
fi

DESTROY_ARGS=("destroy")
if [ "$TFVARS_PATH" != "$TERRAFORM_DIR/terraform.tfvars" ]; then
    DESTROY_ARGS+=("-var-file=$TFVARS_PATH")
fi

if [ "$AUTO_APPROVE" -eq 1 ]; then
    DESTROY_ARGS+=("-auto-approve")
fi

echo "==> Running terraform ${DESTROY_ARGS[*]}"
"$TERRAFORM_EXE" "${DESTROY_ARGS[@]}"

cd "$REPO_ROOT"

echo "==> Selesai. Resource lab berhasil dihancurkan."
