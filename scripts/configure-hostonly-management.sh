#!/bin/bash

VM_NAME="Proxmox-Lab"
HOST_ONLY_ADAPTER_NAME="VirtualBox Host-Only Ethernet Adapter"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -VmName|--vm-name) VM_NAME="$2"; shift ;;
        -HostOnlyAdapterName|--host-only-adapter-name) HOST_ONLY_ADAPTER_NAME="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
source "$SCRIPT_DIR/common.sh"

VBOXMANAGE_EXE=$(assert_resolved_command "VBoxManage" "Install VirtualBox atau letakkan VBoxManage di lokasi yang didukung script." "/c/Program Files/Oracle/VirtualBox/VBoxManage.exe")

echo "==> Checking host-only interface"
HOST_ONLY_IFS=$("$VBOXMANAGE_EXE" list hostonlyifs 2>&1)
if ! echo "$HOST_ONLY_IFS" | grep -qF "$HOST_ONLY_ADAPTER_NAME"; then
    echo "Error: Host-only adapter '$HOST_ONLY_ADAPTER_NAME' tidak ditemukan."
    exit 1
fi

echo "==> Checking VM state"
STATE_LINE=$("$VBOXMANAGE_EXE" showvminfo "$VM_NAME" | grep 'State:')
if echo "$STATE_LINE" | grep -q 'running'; then
    echo "Error: VM '$VM_NAME' masih running. Matikan dulu VM sebelum mengubah network adapter."
    exit 1
fi

echo "==> Configuring NIC2 as host-only"
"$VBOXMANAGE_EXE" modifyvm "$VM_NAME" --nic2 hostonly --hostonlyadapter2 "$HOST_ONLY_ADAPTER_NAME" --nictype2 82540EM --cableconnected2 on

echo "==> Current NIC summary"
"$VBOXMANAGE_EXE" showvminfo "$VM_NAME" | grep -E 'NIC 1:|NIC 2:'

echo "==> Selesai. Langkah berikutnya adalah mengatur IP guest Proxmox pada NIC host-only, misalnya 192.168.56.20/24."
