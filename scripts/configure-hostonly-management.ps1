[CmdletBinding()]
param(
    [string]$VmName = "Proxmox-Lab",
    [string]$HostOnlyAdapterName = "VirtualBox Host-Only Ethernet Adapter"
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "common.ps1")

$vboxManageExe = Assert-ResolvedCommand -CommandName "VBoxManage" -CandidatePaths @(
    "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
) -InstallHint "Install VirtualBox atau letakkan VBoxManage di lokasi yang didukung script."

Write-Host "==> Checking host-only interface"
$hostOnlyIfs = & $vboxManageExe list hostonlyifs
if ($LASTEXITCODE -ne 0) {
    throw "Gagal membaca daftar host-only interface VirtualBox."
}

if ($hostOnlyIfs -notmatch [regex]::Escape($HostOnlyAdapterName)) {
    throw "Host-only adapter '$HostOnlyAdapterName' tidak ditemukan."
}

Write-Host "==> Checking VM state"
$stateLine = (& $vboxManageExe showvminfo $VmName | Select-String 'State:').ToString()
if ($stateLine -match 'running') {
    throw "VM '$VmName' masih running. Matikan dulu VM sebelum mengubah network adapter."
}

Write-Host "==> Configuring NIC2 as host-only"
& $vboxManageExe modifyvm $VmName --nic2 hostonly --hostonlyadapter2 $HostOnlyAdapterName --nictype2 82540EM --cableconnected2 on
if ($LASTEXITCODE -ne 0) {
    throw "Gagal mengonfigurasi NIC2 host-only untuk VM '$VmName'."
}

Write-Host "==> Current NIC summary"
& $vboxManageExe showvminfo $VmName | Select-String 'NIC 1:|NIC 2:'
if ($LASTEXITCODE -ne 0) {
    throw "Gagal membaca ringkasan NIC untuk VM '$VmName'."
}

Write-Host "==> Selesai. Langkah berikutnya adalah mengatur IP guest Proxmox pada NIC host-only, misalnya 192.168.56.20/24."
