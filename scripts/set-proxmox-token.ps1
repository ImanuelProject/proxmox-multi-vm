[CmdletBinding()]
param(
    [string]$TokenValue,
    [string]$EnvironmentName,
    [string]$VarFile,
    [switch]$SkipApiCheck
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "common.ps1")

function Get-TfvarsValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    $pattern = "(?m)^\s*$([regex]::Escape($Key))\s*=\s*(.+?)\s*$"
    $match = [regex]::Match($Content, $pattern)
    if (-not $match.Success) {
        return $null
    }

    return $match.Groups[1].Value.Trim()
}

function Convert-TfvarsLiteral {
    param(
        [string]$Value
    )

    if (-not $Value) {
        return $null
    }

    if (
        $Value.Length -ge 2 -and
        $Value.StartsWith('"') -and
        $Value.EndsWith('"')
    ) {
        return $Value.Substring(1, $Value.Length - 2)
    }

    return $Value
}

function Invoke-ProxmoxVersionCheck {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Endpoint,

        [Parameter(Mandatory = $true)]
        [string]$TokenValue,

        [bool]$TlsInsecure
    )

    $versionUri = ([Uri]::new($Endpoint.TrimEnd('/') + "/api2/json/version")).AbsoluteUri
    $curlExe = Get-Command "curl.exe" -ErrorAction SilentlyContinue

    if ($curlExe) {
        $curlArgs = @()
        if ($TlsInsecure) {
            $curlArgs += "-k"
        }
        $curlArgs += @(
            "-sS",
            "--http1.1",
            "--connect-timeout",
            "5",
            "--max-time",
            "15",
            "-o",
            "-",
            "-w",
            "__HTTP_CODE__:%{http_code}",
            "-H",
            "Authorization: PVEAPIToken=$TokenValue",
            $versionUri
        )

        $curlOutput = & $curlExe.Source @curlArgs 2>&1
        $curlMessage = ($curlOutput | Out-String).Trim()

        if ($LASTEXITCODE -ne 0) {
            throw "curl.exe gagal menghubungi Proxmox API. Detail: $curlMessage"
        }

        $codeMarker = "__HTTP_CODE__:"
        $markerIndex = $curlMessage.LastIndexOf($codeMarker)
        if ($markerIndex -lt 0) {
            throw "curl.exe tidak mengembalikan HTTP status yang bisa diparse. Detail: $curlMessage"
        }

        $responseBody = $curlMessage.Substring(0, $markerIndex).Trim()
        $httpCode = $curlMessage.Substring($markerIndex + $codeMarker.Length).Trim()

        if ($httpCode -eq "401" -or $responseBody -match "Authentication failed") {
            throw "401 Authentication failed"
        }

        if ($httpCode -ne "200") {
            throw "curl.exe menerima HTTP $httpCode dari Proxmox API. Detail: $responseBody"
        }

        if (-not $responseBody) {
            throw "Respons Proxmox API kosong."
        }

        try {
            return $responseBody | ConvertFrom-Json
        }
        catch {
            throw "Respons Proxmox API bukan JSON yang valid."
        }
    }

    $headers = @{ Authorization = "PVEAPIToken=$TokenValue" }
    if (Get-Command Invoke-RestMethod -ErrorAction SilentlyContinue) {
        $oldCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback
        $oldProtocols = [System.Net.ServicePointManager]::SecurityProtocol
        try {
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
            if ($TlsInsecure) {
                [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
            }

            return Invoke-RestMethod -Uri $versionUri -Headers $headers -Method Get
        }
        catch {
            throw $_
        }
        finally {
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $oldCallback
            [System.Net.ServicePointManager]::SecurityProtocol = $oldProtocols
        }
    }

    throw "Tidak ada metode HTTP yang tersedia untuk menguji Proxmox API."
}

if (-not $TokenValue) {
    $secureToken = Read-Host "Masukkan token Proxmox (format: root@pam!terraform=SECRET)" -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
    try {
        $TokenValue = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

if (-not $TokenValue) {
    throw "Token kosong. Tidak ada perubahan pada sesi PowerShell ini."
}

$TokenValue = $TokenValue.Trim()

if ($TokenValue -notmatch '^[^@\s]+@[^!\s]+![^=\s]+=.+' ) {
    throw "Format token tidak valid. Gunakan format USER@REALM!TOKENID=SECRET."
}

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$varFilePath = Resolve-TerraformVarFile -RepoRoot $repoRoot -EnvironmentName $EnvironmentName -VarFile $VarFile
$tfvarsContent = Get-Content -LiteralPath $varFilePath -Raw

$proxmoxEndpoint = Convert-TfvarsLiteral (Get-TfvarsValue -Content $tfvarsContent -Key "proxmox_endpoint")
if (-not $proxmoxEndpoint) {
    $proxmoxEndpoint = "https://192.168.56.20:8006/"
}

$tlsInsecureLiteral = Convert-TfvarsLiteral (Get-TfvarsValue -Content $tfvarsContent -Key "proxmox_tls_insecure")
$proxmoxTlsInsecure = $false
if ($null -ne $tlsInsecureLiteral) {
    $proxmoxTlsInsecure = $tlsInsecureLiteral.ToLowerInvariant() -eq "true"
}

$env:TF_VAR_proxmox_api_token = $TokenValue

Write-Host "==> TF_VAR_proxmox_api_token sudah diset untuk sesi PowerShell ini."
Write-Host "==> Endpoint Proxmox: $proxmoxEndpoint"
Write-Host "==> Var file aktif: $varFilePath"

if ($SkipApiCheck) {
    Write-Host "==> SkipApiCheck aktif. Validasi ke API dilewati."
    return
}

Write-Host "==> Menguji token ke Proxmox API..."

try {
    $response = Invoke-ProxmoxVersionCheck -Endpoint $proxmoxEndpoint -TokenValue $TokenValue -TlsInsecure:$proxmoxTlsInsecure
}
catch {
    $message = $_.Exception.Message
    if ($message -match '401|Authentication failed') {
        throw "Token ditolak oleh Proxmox API. Pastikan token terbaru, format lengkap, dan shell ini memakai nilai yang benar."
    }

    throw "Gagal menguji token ke Proxmox API '$proxmoxEndpoint'. Detail: $message"
}

if (-not $response.data.version) {
    throw "Token berhasil dipakai, tetapi respons versi Proxmox tidak valid."
}

Write-Host "==> Token valid. Proxmox API merespons versi $($response.data.version)."
Write-Host "==> Lanjutkan dengan: .\scripts\check-prereqs.ps1"
