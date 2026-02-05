#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
set -euxo pipefail

PREFIX=${PREFIX:-/usr/local}
AOM_SRC="${SCRIPT_DIR}"/../sources/aom

# Fix nasm 3.x detection - aom checks "nasm -hf" but 3.x moved -O docs to "nasm -h"
sed -i 's/\${CMAKE_ASM_NASM_COMPILER} -hf/\${CMAKE_ASM_NASM_COMPILER} -h/g' "${AOM_SRC}/build/cmake/aom_optimization.cmake"

cd "${AOM_SRC}"
rm -rf aom_build
mkdir -p aom_build
cd aom_build
cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="${PREFIX}" -DENABLE_SHARED=off -DENABLE_NASM=on -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_CXX_FLAGS="$CXXFLAGS" ..
make -j$(nproc) install
