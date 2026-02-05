#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
set -euxo pipefail

PREFIX=${PREFIX:-/usr/local}

cd "${SCRIPT_DIR}"/../sources/opus
./autogen.sh
./configure --prefix="${PREFIX}" --disable-shared
make -j$(nproc)
make install
