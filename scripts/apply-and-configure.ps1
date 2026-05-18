[CmdletBinding()]
param(
    [switch]$SkipTerraformInit,
    [switch]$SkipAnsible,
    [switch]$AutoApprove,
    [int]$ApplyParallelism = 0
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "common.ps1")

$repoRoot = Split-Path -Parent $PSScriptRoot
$terraformDir = Join-Path $repoRoot "terraform"
$ansibleDir = Join-Path $repoRoot "ansible"
$inventoryPath = Join-Path $ansibleDir "inventory.ini"
$playbookPath = Join-Path $ansibleDir "playbook.yml"
$tfvarsPath = Join-Path $terraformDir "terraform.tfvars"
$terraformExe = Assert-ResolvedCommand -CommandName "terraform" -CandidatePaths @(
    "D:\aplikasi\terraform\terraform.exe"
) -InstallHint "Install Terraform atau letakkan binary di lokasi yang didukung script."

if ($SkipAnsible) {
    & (Join-Path $PSScriptRoot "check-prereqs.ps1")
}
else {
    & (Join-Path $PSScriptRoot "check-prereqs.ps1") -RequireAnsible
}
if (-not $?) {
    throw "Prerequisite check gagal."
}

Push-Location $terraformDir
try {
    if (-not $SkipTerraformInit) {
        Write-Host "==> Running terraform init"
        & $terraformExe init
        if ($LASTEXITCODE -ne 0) {
            throw "terraform init gagal."
        }
    }

    $applyArgs = @("apply")
    $resolvedParallelism = $ApplyParallelism
    if ($resolvedParallelism -le 0 -and (Test-Path -LiteralPath $tfvarsPath)) {
        $workloadTypeMatch = Select-String -Path $tfvarsPath -Pattern '^\s*workload_type\s*=\s*"(?<type>[^"]+)"' | Select-Object -First 1
        if ($workloadTypeMatch -and $workloadTypeMatch.Matches[0].Groups["type"].Value -eq "lxc") {
            $resolvedParallelism = 1
        }
    }

    if ($resolvedParallelism -gt 0) {
        $applyArgs += "-parallelism=$resolvedParallelism"
    }

    if ($AutoApprove) {
        $applyArgs += "-auto-approve"
    }

    Write-Host "==> Running terraform $($applyArgs -join ' ')"
    & $terraformExe @applyArgs
    if ($LASTEXITCODE -ne 0) {
        throw "terraform apply gagal."
    }
}
finally {
    Pop-Location
}

Write-Host "==> Checking generated Ansible inventory"
& (Join-Path $PSScriptRoot "check-prereqs.ps1") -RequireInventory
if (-not $?) {
    throw "Inventory check gagal."
}

if ($SkipAnsible) {
    Write-Host "==> SkipAnsible aktif. Flow berhenti setelah terraform apply."
    Write-Host "Inventory tersedia di: $inventoryPath"
    exit 0
}

$workloadType = $null
$vmStarted = $null
if (Test-Path -LiteralPath $tfvarsPath) {
    $workloadTypeMatch = Select-String -Path $tfvarsPath -Pattern '^\s*workload_type\s*=\s*"(?<type>[^"]+)"' | Select-Object -First 1
    if ($workloadTypeMatch) {
        $workloadType = $workloadTypeMatch.Matches[0].Groups["type"].Value
    }

    $vmStartedMatch = Select-String -Path $tfvarsPath -Pattern '^\s*vm_started\s*=\s*(?<value>true|false)\s*$' | Select-Object -First 1
    if ($vmStartedMatch) {
        $vmStarted = [System.Convert]::ToBoolean($vmStartedMatch.Matches[0].Groups["value"].Value)
    }
}

if ($workloadType -eq "vm" -and $vmStarted -eq $false) {
    throw "Ansible diblokir untuk workload_type = `"vm`" dengan vm_started = false. Gunakan -SkipAnsible atau ubah vm_started = true."
}

$wslExe = Assert-WslCommand -CommandName "ansible-playbook" -InstallHint "Install Ansible di distro WSL2 atau gunakan -SkipAnsible."
$ansibleDirWsl = Convert-WindowsPathToWslPath -WindowsPath $ansibleDir
$inventoryPathWsl = Convert-WindowsPathToWslPath -WindowsPath $inventoryPath
$playbookPathWsl = Convert-WindowsPathToWslPath -WindowsPath $playbookPath
$bashCommand = "cd $(Quote-BashLiteral $ansibleDirWsl) && ansible-playbook -i $(Quote-BashLiteral $inventoryPathWsl) $(Quote-BashLiteral $playbookPathWsl)"

Write-Host "==> Running ansible-playbook via WSL"
& $wslExe sh -lc $bashCommand
if ($LASTEXITCODE -ne 0) {
    throw "ansible-playbook gagal di WSL."
}

Write-Host "==> Selesai. Terraform dan Ansible berhasil dijalankan."
