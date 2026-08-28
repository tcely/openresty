#!/usr/bin/env bash

#CACHE_ROOT="${GITHUB_WORKSPACE}/.openresty-cache"
CACHE_ROOT="${GITHUB_WORKSPACE}/download-cache"
CACHE_ARCHIVES="${CACHE_ROOT}/get-tarball"
CACHE_UNPACKED="${CACHE_ROOT}/unpacked"


_cache_ensure_dirs() {
    mkdir -p "${CACHE_ARCHIVES}" "${CACHE_UNPACKED}"
}

_cache_unpack_tar() {
    pushd "${CACHE_UNPACKED}"
    local _f ; for _f in "${CACHE_ARCHIVES}"/*.tar* ; do
        tar -xf "${_f}"
    done
    popd
}


cache_pre() {
    _cache_ensure_dirs
}

cache_post() {
    _cache_ensure_dirs
    _cache_unpack_tar
}
