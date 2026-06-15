#!/bin/bash

TOKEN_VALUE=""
ENVIRONMENT_NAME=""
VAR_FILE=""
SKIP_API_CHECK=0

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -TokenValue|--token-value) TOKEN_VALUE="$2"; shift ;;
        -EnvironmentName|--environment-name) ENVIRONMENT_NAME="$2"; shift ;;
        -VarFile|--var-file) VAR_FILE="$2"; shift ;;
        -SkipApiCheck|--skip-api-check) SKIP_API_CHECK=1 ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

SCRIPT_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
source "$SCRIPT_DIR/common.sh"

function get_tfvars_value() {
    local content="$1"
    local key="$2"
    echo "$content" | grep -E "^\s*$(echo "$key" | sed 's/\./\\./g')\s*=" | head -n 1 | sed -E 's/.*=\s*(.*)/\1/' | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

function convert_tfvars_literal() {
    local val="$1"
    if [[ "$val" == \"*\" ]]; then
        echo "${val:1:-1}"
    else
        echo "$val"
    fi
}

if [ -z "$TOKEN_VALUE" ]; then
    read -r -s -p "Masukkan token Proxmox (format: root@pam!terraform=SECRET): " TOKEN_VALUE
    echo ""
fi

if [ -z "$TOKEN_VALUE" ]; then
    echo "Error: Token kosong. Tidak ada perubahan pada environment."
    exit 1
fi

TOKEN_VALUE=$(echo "$TOKEN_VALUE" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

if ! echo "$TOKEN_VALUE" | grep -qE '^[^@[:space:]]+@[^![:space:]]+![^=[:space:]]+=.+'; then
    echo "Error: Format token tidak valid. Gunakan format USER@REALM!TOKENID=SECRET."
    exit 1
fi

REPO_ROOT=$(dirname "$SCRIPT_DIR")
VAR_FILE_PATH=$(resolve_terraform_var_file "$REPO_ROOT" "$ENVIRONMENT_NAME" "$VAR_FILE" "false")
TFVARS_CONTENT=$(cat "$VAR_FILE_PATH")

PROXMOX_ENDPOINT_LITERAL=$(get_tfvars_value "$TFVARS_CONTENT" "proxmox_endpoint")
PROXMOX_ENDPOINT=$(convert_tfvars_literal "$PROXMOX_ENDPOINT_LITERAL")
if [ -z "$PROXMOX_ENDPOINT" ]; then
    PROXMOX_ENDPOINT="https://192.168.56.20:8006/"
fi

TLS_INSECURE_LITERAL=$(get_tfvars_value "$TFVARS_CONTENT" "proxmox_tls_insecure")
PROXMOX_TLS_INSECURE="false"
if [ -n "$TLS_INSECURE_LITERAL" ]; then
    if echo "$TLS_INSECURE_LITERAL" | grep -qi "true"; then
        PROXMOX_TLS_INSECURE="true"
    fi
fi

export TF_VAR_proxmox_api_token="$TOKEN_VALUE"

echo "==> TF_VAR_proxmox_api_token sudah diset untuk sesi ini."
echo "==> Pastikan Anda menjalankan perintah ini menggunakan 'source ./scripts/set-proxmox-token.sh' agar environment variable tersimpan di shell Anda."
echo "==> Endpoint Proxmox: $PROXMOX_ENDPOINT"
echo "==> Var file aktif: $VAR_FILE_PATH"

if [ "$SKIP_API_CHECK" -eq 1 ]; then
    echo "==> SkipApiCheck aktif. Validasi ke API dilewati."
    exit 0
fi

echo "==> Menguji token ke Proxmox API..."

CURL_ARGS=("-sS" "--http1.1" "--connect-timeout" "5" "--max-time" "15" "-w" "\n%{http_code}" "-H" "Authorization: PVEAPIToken=$TOKEN_VALUE")
if [ "$PROXMOX_TLS_INSECURE" = "true" ]; then
    CURL_ARGS+=("-k")
fi

VERSION_URI="${PROXMOX_ENDPOINT%/}/api2/json/version"

CURL_OUTPUT=$(curl "${CURL_ARGS[@]}" "$VERSION_URI" 2>&1) || true
HTTP_CODE=$(echo "$CURL_OUTPUT" | tail -n1)
RESPONSE_BODY=$(echo "$CURL_OUTPUT" | sed '$d')

if [ "$HTTP_CODE" = "401" ] || echo "$RESPONSE_BODY" | grep -q "Authentication failed"; then
    echo "Error: Token ditolak oleh Proxmox API. Pastikan token terbaru, format lengkap, dan shell ini memakai nilai yang benar."
    exit 1
fi

if [ "$HTTP_CODE" != "200" ]; then
    echo "Error: Menerima HTTP $HTTP_CODE dari Proxmox API. Detail: $RESPONSE_BODY"
    exit 1
fi

if command -v jq >/dev/null 2>&1; then
    VERSION=$(echo "$RESPONSE_BODY" | jq -r '.data.version // empty')
else
    VERSION=$(echo "$RESPONSE_BODY" | grep -oE '"version":"[^"]+"' | head -n1 | cut -d'"' -f4)
fi

if [ -z "$VERSION" ]; then
    VERSION="Unknown (jq not installed)"
fi

echo "==> Token valid. Proxmox API merespons versi $VERSION."
echo "==> Lanjutkan dengan: ./scripts/check-prereqs.sh"
