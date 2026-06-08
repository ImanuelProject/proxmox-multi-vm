#!/bin/bash

VM_NAME="Proxmox-Lab"
MODE="acpipowerbutton"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -VmName|--vm-name) VM_NAME="$2"; shift ;;
        -Mode|--mode) MODE="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
source "$SCRIPT_DIR/common.sh"

VBOXMANAGE_EXE=$(assert_resolved_command "VBoxManage" "Install VirtualBox atau letakkan VBoxManage di lokasi yang didukung script." "/c/Program Files/Oracle/VirtualBox/VBoxManage.exe")

echo "==> Checking VM registration"
VM_LIST=$("$VBOXMANAGE_EXE" list vms 2>&1)
if ! echo "$VM_LIST" | grep -qF "$VM_NAME"; then
    echo "Error: VM '$VM_NAME' tidak terdaftar di VirtualBox."
    exit 1
fi

echo "==> Sending '$MODE' to VM '$VM_NAME'"
"$VBOXMANAGE_EXE" controlvm "$VM_NAME" "$MODE"

echo "==> Perintah stop untuk VM '$VM_NAME' berhasil dikirim."
