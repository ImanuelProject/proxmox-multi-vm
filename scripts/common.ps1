function Assert-PathExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Description tidak ditemukan: $Path"
    }
}

function Get-ResolvedCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName,

        [string[]]$CandidatePaths = @()
    )

    $existingCommand = Get-Command $CommandName -ErrorAction SilentlyContinue
    if ($existingCommand) {
        return $existingCommand.Source
    }

    foreach ($candidate in $CandidatePaths) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }
    }

    return $null
}

function Assert-ResolvedCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName,

        [string[]]$CandidatePaths = @(),

        [string]$InstallHint
    )

    $resolved = Get-ResolvedCommand -CommandName $CommandName -CandidatePaths $CandidatePaths
    if (-not $resolved) {
        $message = "Command '$CommandName' tidak ditemukan."
        if ($InstallHint) {
            $message += " $InstallHint"
        }
        throw $message
    }

    return $resolved
}

function Assert-WslCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName,

        [string]$InstallHint
    )

    $wslExe = Assert-ResolvedCommand -CommandName "wsl.exe" -InstallHint "Pastikan WSL2 tersedia di Windows host."
    & $wslExe sh -lc "command -v $CommandName >/dev/null 2>&1"
    if ($LASTEXITCODE -ne 0) {
        $message = "Command '$CommandName' tidak ditemukan di WSL."
        if ($InstallHint) {
            $message += " $InstallHint"
        }
        throw $message
    }

    return $wslExe
}

function Convert-WindowsPathToWslPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WindowsPath
    )

    $wslExe = Assert-ResolvedCommand -CommandName "wsl.exe" -InstallHint "Pastikan WSL2 tersedia di Windows host."
    $converted = & $wslExe wslpath -a -u $WindowsPath
    if ($LASTEXITCODE -ne 0 -or -not $converted) {
        throw "Gagal mengonversi path Windows ke path WSL: $WindowsPath"
    }

    return ($converted | Select-Object -First 1).Trim()
}

function Quote-BashLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return "'" + $Value.Replace("'", "'\''") + "'"
}
