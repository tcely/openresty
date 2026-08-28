#!/usr/bin/env bash

#CACHE_ROOT="${GITHUB_WORKSPACE:-.}/.openresty-cache"
CACHE_ROOT="${GITHUB_WORKSPACE:-.}/download-cache"
CACHE_ARCHIVES="${CACHE_ROOT}/get-tarball"
CACHE_STATIC_LIBS="${CACHE_ROOT}/libs/static"
CACHE_UNPACKED="${CACHE_ROOT}/unpacked"


_cache_ensure_dirs() {
    mkdir -p "${CACHE_ARCHIVES}" "${CACHE_STATIC_LIBS}" "${CACHE_UNPACKED}"
}

_cache_save_libs() {
    local d="$(find . -maxdepth 1 -name 'openresty-*' -type d -print | head -n 1 | cut -c 3-)"
    mkdir -v -p "${CACHE_STATIC_LIBS}/${d}/objs/lib"
    local s
    for s in "${d}/objs/lib"/zlib-*/libz.a "${d}/objs/lib"/pcre2-*/.libs/libpcre2*.a "${d}/objs/lib"/openssl-*/.openssl/lib/lib*.a
    do
        [ -f "${s}" ] || continue
        mkdir -p "${CACHE_STATIC}/${s}"
        rmdir "${CACHE_STATIC}/${s}"
        mv -v "${s}" "${CACHE_STATIC}/${s}"
    done
}

_cache_unpack_tar() {
    pushd "${CACHE_UNPACKED}"
    local _f ; for _f in "${CACHE_ARCHIVES}"/*.tar* ; do
        [ -s "${_f}" ] || continue
        tar -xf "${_f}"
    done
    popd
}


cache_pre() {
    _cache_ensure_dirs
}

cache_post() {
    _cache_ensure_dirs
    _cache_save_libs
    _cache_unpack_tar
}
