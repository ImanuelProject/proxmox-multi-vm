[CmdletBinding()]
param(
    [switch]$SkipTerraformInit,
    [switch]$AutoApprove,
    [string]$EnvironmentName,
    [string]$VarFile
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "common.ps1")

$repoRoot = Split-Path -Parent $PSScriptRoot
$terraformDir = Join-Path $repoRoot "terraform"
$tfvarsPath = Resolve-TerraformVarFile -RepoRoot $repoRoot -EnvironmentName $EnvironmentName -VarFile $VarFile
$terraformExe = Assert-ResolvedCommand -CommandName "terraform" -CandidatePaths @(
    "D:\aplikasi\terraform\terraform.exe"
) -InstallHint "Install Terraform atau letakkan binary di lokasi yang didukung script."

& (Join-Path $PSScriptRoot "check-prereqs.ps1") -EnvironmentName $EnvironmentName -VarFile $VarFile
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
    if ($tfvarsPath -ne (Join-Path $terraformDir "terraform.tfvars")) {
        $destroyArgs += "-var-file=$tfvarsPath"
    }
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
