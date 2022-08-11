#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
set -euxo pipefail

default_install=$(realpath "${SCRIPT_DIR}"/../install)
PREFIX=${PREFIX:-"${default_install}"}
DESTDIR=${DESTDIR:-}
DEBUG=${DEBUG:-1}

if [ "${DEBUG}" = "1" ]; then
	FLAGS="--enable-debug"
else
	FLAGS="--disable-debug"
fi

# Install it
cd "${SCRIPT_DIR}"/../sources/x265/build/linux
PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="${PREFIX}" -DENABLE_SHARED=off ../../source
PATH="$HOME/bin:$PATH" make -j$(nproc)
make -j$(nproc) install DESTDIR="${DESTDIR}"
