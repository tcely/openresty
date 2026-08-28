#!/usr/bin/env bash

set -euo pipefail

script_dir="$(dirname "$0")"
script_name="$(basename "$0")"

# the current directory is one level down
parent_dir="$(realpath -L -e "..")"
# a copy of this original source is running
script_dir="$(realpath -L -e "${parent_dir}/util")"

PCRE='pcre2-10.47'
ZLIB='zlib-1.3.2'
OPENSSL='openssl-3.5.6'
JOBS=12

download_and_extract() {
    local outfile="${1}.tar.gz"
    local url="${2}"
    local finalpath="${parent_dir}/${outfile}"

    if [ ! -s "${finalpath}" ]; then
        bash "${script_dir}/get-tarball" "${url}" -O "${outfile}" &&
            mv "${outfile}" "${finalpath}"
    fi

    tar -xf "${finalpath}"
}

[ ! -e objs ] || ( mv -f objs .remove.objs && rm -rf .remove.objs & )
mkdir -p objs/lib && pushd objs/lib

download_and_extract "${OPENSSL}" "https://github.com/openssl/openssl/releases/download/${OPENSSL}/${OPENSSL}.tar.gz"
download_and_extract "${ZLIB}" "http://zlib.net/${ZLIB}.tar.gz"
download_and_extract "${PCRE}" "https://github.com/PCRE2Project/pcre2/releases/download/${PCRE}/${PCRE}.tar.gz"

ls "${parent_dir}" .

popd

pushd "objs/lib/${OPENSSL}"
patch -p1 < "${parent_dir}/patches/openssl-3.5.5-sess_set_get_cb_yield.patch"
popd

    #--with-openssl-opt="no-asm" \

./configure \
    --with-cc='gcc' \
    --platform='msys' \
    --prefix= \
    --with-cc-opt='-DFD_SETSIZE=1024' \
    --sbin-path='nginx.exe' \
    --with-pcre-jit \
    --without-http_rds_json_module \
    --without-http_rds_csv_module \
    --without-lua_rds_parser \
    --with-ipv6 \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-http_v2_module \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --without-mail_smtp_module \
    --with-http_stub_status_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_secure_link_module \
    --with-http_random_index_module \
    --with-http_gzip_static_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-select_module \
    --with-luajit-xcflags='-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT' \
    --with-pcre="objs/lib/${PCRE}" \
    --with-zlib="objs/lib/${ZLIB}" \
    --with-openssl="objs/lib/${OPENSSL}" \
    "-j${JOBS}"

make "-j${JOBS}"
exec make install
