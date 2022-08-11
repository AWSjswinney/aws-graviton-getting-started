#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
set -euxo pipefail

default_install=$(realpath "${SCRIPT_DIR}"/../install)
PREFIX=${PREFIX:-"${default_install}"}
DESTDIR=${DESTDIR:-}
DEBUG=${DEBUG:-1}
FLAGS=""

if [ "${DEBUG}" = "1" ]; then
	FLAGS="--enable-debug"
fi

# Install it
cd "${SCRIPT_DIR}"/../sources/x264
./configure --prefix="${PREFIX}" --enable-static --disable-lavf ${FLAGS}
make -j$(nproc) install DESTDIR="${DESTDIR}"
