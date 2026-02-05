#!/bin/bash
# Setup compiler environment variables based on COMPILER setting
set -e

COMPILER=${COMPILER:-gcc}
TARGET_PLATFORM=${TARGET_PLATFORM:-}

# Set compiler
case "$COMPILER" in
    gcc)
        CC=gcc
        CXX=g++
        ;;
    gcc[0-9]*)
        ver="${COMPILER#gcc}"
        if command -v gcc-${ver} &>/dev/null; then
            CC=gcc-${ver}
            CXX=g++-${ver}
        elif command -v gcc${ver}-gcc &>/dev/null; then
            # AL2023 uses gcc14-gcc naming
            CC=gcc${ver}-gcc
            CXX=gcc${ver}-g++
        else
            CC=gcc${ver}
            CXX=g++${ver}
        fi
        ;;
    clang)
        CC=clang
        CXX=clang++
        ;;
    clang[0-9]*)
        ver="${COMPILER#clang}"
        if command -v clang-${ver} &>/dev/null; then
            CC=clang-${ver}
            CXX=clang++-${ver}
        else
            CC=clang${ver}
            CXX=clang++${ver}
        fi
        ;;
esac

# Set platform-specific flags
CFLAGS=""
case "$TARGET_PLATFORM" in
    graviton2)
        CFLAGS="-march=armv8.2-a+crypto+fp16+rcpc+dotprod -mtune=neoverse-n1"
        ;;
    graviton3)
        CFLAGS="-march=armv8.4-a+crypto+fp16+rcpc+dotprod+sve -mtune=neoverse-v1"
        ;;
    graviton4)
        CFLAGS="-march=armv9-a+crypto+fp16+rcpc+dotprod+sve2 -mtune=neoverse-v2"
        ;;
    avx2)
        CFLAGS="-march=haswell -mtune=haswell"
        ;;
    avx512)
        CFLAGS="-march=skylake-avx512 -mtune=skylake-avx512"
        ;;
esac

cat > /etc/profile.d/compiler.sh << EOF
export CC=$CC
export CXX=$CXX
export CFLAGS="$CFLAGS"
export CXXFLAGS="$CFLAGS"
EOF

chmod +x /etc/profile.d/compiler.sh
