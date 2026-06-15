#!/bin/bash

# common.sh
# Helpers for Proxmox Lab scripts

set -e

function assert_path_exists() {
    local path="$1"
    local description="$2"
    if [ ! -e "$path" ]; then
        echo "Error: $description tidak ditemukan: $path"
        exit 1
    fi
}

function get_resolved_command() {
    local cmd_name="$1"
    shift
    local candidate_paths=("$@")

    if command -v "$cmd_name" >/dev/null 2>&1; then
        command -v "$cmd_name"
        return
    fi

    for candidate in "${candidate_paths[@]}"; do
        if [ -n "$candidate" ] && [ -x "$candidate" ]; then
            echo "$candidate"
            return
        fi
    done
}

function assert_resolved_command() {
    local cmd_name="$1"
    local install_hint="$2"
    shift 2
    local candidate_paths=("$@")

    local resolved
    resolved=$(get_resolved_command "$cmd_name" "${candidate_paths[@]}")

    if [ -z "$resolved" ]; then
        local msg="Command '$cmd_name' tidak ditemukan."
        if [ -n "$install_hint" ]; then
            msg="$msg $install_hint"
        fi
        echo "Error: $msg" >&2
        exit 1
    fi

    echo "$resolved"
}

function assert_wsl_command() {
    local cmd_name="$1"
    local install_hint="$2"

    if [ "$(uname)" = "Linux" ]; then
        if [ -d "$HOME/.local/bin" ]; then
            export PATH="$HOME/.local/bin:$PATH"
        fi

        if ! command -v "$cmd_name" >/dev/null 2>&1; then
            local msg="Command '$cmd_name' tidak ditemukan."
            if [ -n "$install_hint" ]; then
                msg="$msg $install_hint"
            fi
            echo "Error: $msg" >&2
            exit 1
        fi
        echo "DIRECT_EXEC"
        return
    fi

    local wsl_exe
    wsl_exe=$(assert_resolved_command "wsl.exe" "Pastikan WSL2 tersedia di Windows host.")
    
    if ! "$wsl_exe" sh -lc "command -v $cmd_name >/dev/null 2>&1"; then
        local msg="Command '$cmd_name' tidak ditemukan di WSL."
        if [ -n "$install_hint" ]; then
            msg="$msg $install_hint"
        fi
        echo "Error: $msg" >&2
        exit 1
    fi

    echo "$wsl_exe"
}

function convert_windows_path_to_wsl_path() {
    local win_path="$1"

    if [ "$(uname)" = "Linux" ]; then
        echo "$win_path"
        return
    fi

    local wsl_exe
    wsl_exe=$(assert_resolved_command "wsl.exe" "Pastikan WSL2 tersedia di Windows host.")
    
    local converted
    converted=$("$wsl_exe" wslpath -a -u "$win_path" 2>/dev/null) || true
    
    if [ -z "$converted" ]; then
        echo "Error: Gagal mengonversi path Windows ke path WSL: $win_path" >&2
        exit 1
    fi
    
    echo "$converted"
}

function quote_bash_literal() {
    local val="$1"
    echo "'${val//\'/\'\'}'"
}

function resolve_terraform_var_file() {
    local repo_root="$1"
    local env_name="$2"
    local var_file="$3"
    local allow_missing="$4"

    if [ -n "$env_name" ] && [ -n "$var_file" ]; then
        echo "Error: Gunakan salah satu: -EnvironmentName atau -VarFile, jangan keduanya." >&2
        exit 1
    fi

    local resolved_path=""
    if [ -n "$var_file" ]; then
        if [[ "$var_file" = /* ]] || [[ "$var_file" = *:* ]]; then
            resolved_path="$var_file"
        else
            resolved_path="$repo_root/$var_file"
        fi
    elif [ -n "$env_name" ]; then
        resolved_path="$repo_root/terraform/environments/$env_name.tfvars"
    else
        resolved_path="$repo_root/terraform/terraform.tfvars"
    fi

    local full_path
    if command -v cygpath >/dev/null 2>&1; then
        full_path=$(cygpath -m "$resolved_path")
    else
        full_path=$(readlink -f "$resolved_path")
    fi

    if [ "$allow_missing" != "true" ]; then
        assert_path_exists "$full_path" "File Terraform variables"
    fi

    echo "$full_path"
}
