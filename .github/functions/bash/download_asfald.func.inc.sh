#!/usr/bin/env bash

stdout() {
    printf -- '%s\n' "${@}"
}

stderr() {
    printf -- '%s\n' "${@}"
} 1>&2

get_location_header() {
    url="${1}"; shift
    # First-match (head -n 1) is preferred as HTTP allows only one Location header
    location_header="$(curl -sSI -- "${url}" | grep -ie '^Location: ' | head -n 1)"
    # Remove \r from \r\n line-endings
    stdout "${location_header%$(printf '\r')}"
}

# Usage: download_gh_release owner repo template [version] [args...]
download_gh_release() {
    owner="${1}"; shift
    repo="${1}"; shift
    template="${1}"; shift

    _base_url="https://github.com/${owner}/${repo}/releases"

    # Optional: do not shift too far
    _target_version="${1:-latest}"
    [ 0 -ge $# ] || shift

    # Determine the version
    case "${_target_version}" in
        ('latest')
            resolved_version="$(get_location_header "${_base_url}/latest" | cut -d / -f 8)"
            case "${resolved_version:-/}" in
                ('/')
                    stderr \
                    "Error: Could not determine the latest release version for ${owner}/${repo}"
                    return 1
                    ;;
            esac
            ;;
        *)
            resolved_version="${_target_version}"
            ;;
    esac
    unset -v _target_version

    # Generate the filename using printf
    filename=$(printf -- "${template}" "${resolved_version}" "${@}")

    # Construct the download URL
    dl_url="${_base_url}/download/${resolved_version}/${filename}"
    unset -v _base_url

    stdout "Fetching from ${owner}/${repo}: ${filename}"

    curl --progress-bar --fail --location --remote-name --remote-time "${dl_url}"
}

check_sums() {
    local algo="${1}"; shift

    case "$(command -v shasum.py)" in
        (*/shasum.py) shasum.py -a "${algo,,}" "$@" ; return ;;
    esac

    case "${algo,,}" in
        (sha[25]*|sha384) algo='sha2' ;;
    esac
    
    cksum -a "${algo,,}" --check --strict --warn --ignore-missing --debug "$@"
}

verify_digest() {
    local digest="${1}"
    local filename="${2}"

    local algo="${digest%%:*}"
    local checksum="${digest##*:}"
    printf -- '%s (%s) = %s\n' "${algo^^}" "${filename}" "${checksum,,}" | check_sums "${algo,,}" -
}

download_asfald() {
    local owner='asfaload' repo='asfald' tag='v0.6.0'
    local asfald_uri="${owner}/${repo}/releases/download/${tag}/checksums.txt"
    local sums_url="https://gh.checksums.asfaload.com/github.com/${asfald_uri}"

    local os
    case "$(uname -s)" in
        (Darwin) os='apple-darwin' ;;
        (Linux) os='unknown-linux-musl' ;;
    esac
    local arch
    case "$(uname -m)" in
        (aarch64|arm64) arch='aarch64' ;;
        (x86_64) arch='x86_64' ;;
    esac

    case "${1-}" in
        (latest)
            workdir="$(mktemp -d)"
            pushd "${workdir:-"${TMPDIR:-/tmp}"}"
            download_gh_release "${owner}" "${repo}" 'checksums.txt'
            test '!' -f 'checksums.txt' || rm -v 'checksums.txt'
            popd
            test '!' -d "${workdir}" || rmdir -v "${workdir}"
            local latest_version="${resolved_version}"
            test -n "${latest_version}" || return 1
            
            TMPDIR="$(realpath .)" \
                ./asfald -o 'asfald-latest' -w -p '${path}/checksums.txt' -- "https://github.com/${owner}/${repo}/releases/latest/download/asfald-${arch}-${os}" && \
                chmod -v 'a+rx' 'asfald-latest'
            local latest_digest="$(./asfald-latest --get-hash "https://github.com/${owner}/${repo}/releases/download/${latest_version}/asfald-${arch}-${os}")"
            verify_digest "${latest_digest}" 'asfald-latest' || return 1
            ;;
        (*)
            download_gh_release "${owner}" "${repo}" "asfald-${arch}-${os}" "${tag}" && \
                curl -fsSL -- "${sums_url}" | check_sums 'sha256' - && \
                mv -v "asfald-${arch}-${os}" 'asfald' && \
                chmod -v 'a+rx' 'asfald'
            ;;
    esac

}
