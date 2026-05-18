[CmdletBinding()]
param(
    [string]$VmName = "Proxmox-Lab",
    [ValidateSet("gui", "headless")]
    [string]$Type = "gui"
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "common.ps1")

$vboxManageExe = Assert-ResolvedCommand -CommandName "VBoxManage" -CandidatePaths @(
    "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
) -InstallHint "Install VirtualBox atau letakkan VBoxManage di lokasi yang didukung script."

Write-Host "==> Checking VM registration"
$vmList = & $vboxManageExe list vms
if ($LASTEXITCODE -ne 0) {
    throw "Gagal membaca daftar VM VirtualBox."
}

if ($vmList -notmatch [regex]::Escape($VmName)) {
    throw "VM '$VmName' tidak terdaftar di VirtualBox."
}

Write-Host "==> Starting VM '$VmName' with type '$Type'"
& $vboxManageExe startvm $VmName --type $Type
if ($LASTEXITCODE -ne 0) {
    throw "Gagal menyalakan VM '$VmName'."
}

Write-Host "==> VM '$VmName' berhasil dijalankan."
