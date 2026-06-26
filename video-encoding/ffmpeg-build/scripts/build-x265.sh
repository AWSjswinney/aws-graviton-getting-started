#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
set -euxo pipefail

PREFIX=${PREFIX:-/usr/local}
HIGH_BIT_DEPTH=${HIGH_BIT_DEPTH:-0}

# Enable assembly optimizations. This is the bulk of x265's performance on both
# ARM (Neon/DotProd/I8MM/SVE/SVE2) and x86 (nasm), so it must stay on whenever
# the toolchain can build it.
#
# x265's CMake already degrades gracefully across most aarch64 extensions, with
# one gap: its SVE2 assembly (.S) is *always* compiled with
# -march=armv9-a+i8mm+sve2 regardless of target platform. Toolchains that cannot
# assemble that fail the whole build. Empirically (x265 4.1, validated on a
# Graviton4 host) this affects:
#   - gcc   < 12  (cc1 has no armv9-a)
#   - clang < 15  (integrated assembler rejects the SVE2 .S files)
# Every other aarch64 assembly path (~20 objects) still builds on those
# compilers. So instead of disabling ALL assembly (the previous behavior, which
# also needlessly dropped the x86 nasm paths for the default gcc/clang names),
# keep assembly on and disable ONLY SVE2 when the active compiler cannot build
# it. Capability is probed directly so this stays correct for future toolchains
# without per-version maintenance.
BUILD_CONFIG_FLAGS="-DENABLE_ASSEMBLY=ON"

CC_BIN="${CC:-gcc}"
case "$(uname -m)" in
    aarch64|arm64)
        SVE2_PROBE="$(mktemp --suffix=.S)"
        # ptrue (SVE) + sqrdmlah (SVE2), under the exact flag x265 uses for its
        # SVE2 .S files. Uppercase .S routes through the compiler driver (cc1),
        # matching x265's real compile path.
        printf '.arch armv8-a+sve2\n_x265_sve2_probe:\n    ptrue p0.b, vl8\n    sqrdmlah z0.s, z1.s, z2.s\n    ret\n' > "$SVE2_PROBE"
        if ! "${CC_BIN}" -march=armv9-a+i8mm+sve2 -c "$SVE2_PROBE" -o /dev/null >/dev/null 2>&1; then
            echo "x265: ${CC_BIN} cannot assemble SVE2 (-march=armv9-a+i8mm+sve2); disabling SVE2 only, keeping Neon/DotProd/I8MM/SVE assembly"
            BUILD_CONFIG_FLAGS="${BUILD_CONFIG_FLAGS} -DENABLE_SVE2=OFF"
        fi
        rm -f "$SVE2_PROBE"
        ;;
esac

cd "${SCRIPT_DIR}"/../sources/x265/build/linux
rm -rf *

if [ "${HIGH_BIT_DEPTH}" = "1" ]; then
    cmake -G "Unix Makefiles" \
        -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
        -DENABLE_SHARED=off \
        -DHIGH_BIT_DEPTH=on \
        -DENABLE_LIBNUMA=OFF \
        -DCMAKE_C_FLAGS="$CFLAGS" \
        -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
        $BUILD_CONFIG_FLAGS \
        ../../source
else
    cmake -G "Unix Makefiles" \
        -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
        -DENABLE_SHARED=off \
        -DENABLE_LIBNUMA=OFF \
        -DCMAKE_C_FLAGS="$CFLAGS" \
        -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
        $BUILD_CONFIG_FLAGS \
        ../../source
fi

make -j$(nproc) install

# Rename 10-bit CLI binary
if [ "${HIGH_BIT_DEPTH}" = "1" ] && [ -f "${PREFIX}/bin/x265" ]; then
    mv "${PREFIX}/bin/x265" "${PREFIX}/bin/x265-10bit"
fi
