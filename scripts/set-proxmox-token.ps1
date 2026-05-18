[CmdletBinding()]
param(
    [string]$TokenValue
)

$ErrorActionPreference = "Stop"

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

if ($TokenValue -notmatch '^[^@\s]+@[^!\s]+![^=\s]+=.+' ) {
    throw "Format token tidak valid. Gunakan format USER@REALM!TOKENID=SECRET."
}

$env:TF_VAR_proxmox_api_token = $TokenValue

Write-Host "==> TF_VAR_proxmox_api_token sudah diset untuk sesi PowerShell ini."
Write-Host "==> Verifikasi dengan: .\scripts\check-prereqs.ps1"
