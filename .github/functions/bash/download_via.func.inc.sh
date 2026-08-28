#!/usr/bin/env bash

# Default to a hidden file if the environment variable is empty
: "${MANIFEST_PATH:=.download_manifest.jsonl}"

_append_download_task() {
    local url="$1"
    local source="$2"
    local value="$3"
    local output="$4"
    
    printf '{"url":"%s","source":"%s","value":"%s","output":"%s"}\n' \
        "${url}" "${source}" "${value}" "${output}"
} >> "${MANIFEST_PATH}"

clear_download_via_manifest() {
    :
} > "${MANIFEST_PATH}"

download_via_manual_hash() {
    local value="${1}"
    local url="${2}"
    local output="${3-}"

    _append_download_task "${url}" 'manual' "${value}" "${output}"
}

download_via_remote_file() {
    local value="${1}"
    local url="${2}"
    local output="${3-}"

    _append_download_task "${url}" 'remote_file' "${value}" "${output}"
}

download_via_github_api() {
    local url="${1}"
    local output="${2-}"

    _append_download_task "${url}" 'github_api' 'none' "${output}"
}
