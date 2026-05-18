[CmdletBinding()]
param(
    [string]$VmName = "Proxmox-Lab",
    [ValidateSet("acpipowerbutton", "poweroff")]
    [string]$Mode = "acpipowerbutton"
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

Write-Host "==> Sending '$Mode' to VM '$VmName'"
& $vboxManageExe controlvm $VmName $Mode
if ($LASTEXITCODE -ne 0) {
    throw "Gagal menghentikan VM '$VmName' dengan mode '$Mode'."
}

Write-Host "==> Perintah stop untuk VM '$VmName' berhasil dikirim."
