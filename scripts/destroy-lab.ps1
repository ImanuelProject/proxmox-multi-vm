[CmdletBinding()]
param(
    [switch]$SkipTerraformInit,
    [switch]$AutoApprove
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "common.ps1")

$repoRoot = Split-Path -Parent $PSScriptRoot
$terraformDir = Join-Path $repoRoot "terraform"
$terraformExe = Assert-ResolvedCommand -CommandName "terraform" -CandidatePaths @(
    "D:\aplikasi\terraform\terraform.exe"
) -InstallHint "Install Terraform atau letakkan binary di lokasi yang didukung script."

& (Join-Path $PSScriptRoot "check-prereqs.ps1")
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

    $destroyArgs = @("destroy")
    if ($AutoApprove) {
        $destroyArgs += "-auto-approve"
    }

    Write-Host "==> Running terraform $($destroyArgs -join ' ')"
    & $terraformExe @destroyArgs
    if ($LASTEXITCODE -ne 0) {
        throw "terraform destroy gagal."
    }
}
finally {
    Pop-Location
}

Write-Host "==> Selesai. Resource lab berhasil dihancurkan."
