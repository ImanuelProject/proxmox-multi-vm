[CmdletBinding()]
param(
    [switch]$RequireAnsible,
    [switch]$RequireInventory,
    [string]$EnvironmentName,
    [string]$VarFile
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "common.ps1")

$repoRoot = Split-Path -Parent $PSScriptRoot
$terraformDir = Join-Path $repoRoot "terraform"
$ansibleDir = Join-Path $repoRoot "ansible"
$tfvarsPath = Resolve-TerraformVarFile -RepoRoot $repoRoot -EnvironmentName $EnvironmentName -VarFile $VarFile
$playbookPath = Join-Path $ansibleDir "playbook.yml"
$inventoryPath = Join-Path $ansibleDir "inventory.ini"

Write-Host "==> Validating local prerequisites"
Assert-PathExists -Path $terraformDir -Description "Folder terraform"
Assert-PathExists -Path $ansibleDir -Description "Folder ansible"
Assert-PathExists -Path $playbookPath -Description "File playbook Ansible"
Write-Host "==> Terraform var-file: $tfvarsPath"

if (-not $env:TF_VAR_proxmox_api_token) {
    throw "Environment variable 'TF_VAR_proxmox_api_token' belum diset. Contoh: `$env:TF_VAR_proxmox_api_token=`"root@pam!terraform=your-token`""
}

Write-Host "==> TF_VAR_proxmox_api_token tersedia"

$terraformExe = Assert-ResolvedCommand -CommandName "terraform" -CandidatePaths @(
    "D:\aplikasi\terraform\terraform.exe"
) -InstallHint "Install Terraform atau letakkan binary di lokasi yang didukung script."
Write-Host "==> Terraform found at: $terraformExe"

if ($RequireAnsible) {
    $wslExe = Assert-WslCommand -CommandName "ansible-playbook" -InstallHint "Install Ansible di distro WSL2 atau gunakan flow tanpa Ansible."
    Write-Host "==> WSL found at: $wslExe"
    Write-Host "==> ansible-playbook tersedia di WSL"
}

if ($RequireInventory) {
    Assert-PathExists -Path $inventoryPath -Description "Inventory Ansible hasil generate Terraform"
}

Write-Host "==> Prerequisite check selesai."
