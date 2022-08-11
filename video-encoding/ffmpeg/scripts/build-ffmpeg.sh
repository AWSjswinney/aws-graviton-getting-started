#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
set -exo pipefail

default_install=$(realpath "${SCRIPT_DIR}"/../install)
PREFIX=${PREFIX:-"${default_install}"}
DESTDIR=${DESTDIR:-}
DEBUG=${DEBUG:-1}

if [ "${DEBUG}" = "1" ]; then
	FLAGS="--enable-debug"
else
	FLAGS="--disable-debug"
fi

compiler_flags=""
if [ ! -z "$CC" ]; then
    compiler_flags="$compiler_flags --cc=$CC"
fi
if [ ! -z "$CXX" ]; then
    compiler_flags="$compiler_flags --cxx=$CXX"
fi
if [ ! -z "$LD" ]; then
    compiler_flags="$compiler_flags --ld=$LD"
fi

# Install it
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig"
cd "${SCRIPT_DIR}"/../sources/ffmpeg
PATH="${PREFIX}/bin:$PATH" ./configure $compiler_flags \
    --prefix="${PREFIX}" \
    --pkg-config-flags="--static" \
    --extra-libs="-lpthread -lm" \
    --extra-ldflags="-L${PREFIX}/lib" \
    --extra-cflags="-I${PREFIX}/include" \
    --extra-cxxflags="-I${PREFIX}/include" \
    --bindir="${PREFIX}/bin" \
    --incdir="${PREFIX}/include" \
    --libdir="${PREFIX}/lib" \
    --enable-rpath \
    --enable-gpl \
    --enable-libx264 \
    --enable-libx265 \
    --enable-nonfree \
    --disable-stripping
PATH="$HOME/bin:$PATH" make -j$(nproc)
make install
#ldconfig
