#!/bin/bash
# Install build dependencies for each supported distro.
#
# CUSTOMIZATION: To add a new distro:
#   1. Add a new function: <distro>_dependencies()
#   2. Add detection logic at the bottom of this script
#
set -xe

if [[ $(id -u) -ne 0 ]]; then
    echo "Must run with root privileges"
    exit 1
fi

function amazon_linux_2023_dependencies() {
    dnf install -y \
        autoconf \
        automake \
        bc \
        bzip2 \
        bzip2-devel \
        cmake \
        freetype-devel \
        gcc \
        gcc-c++ \
        git \
        libtool \
        make \
        numactl-devel \
        ninja-build \
        pkgconfig \
        python3-pip \
        nasm \
        wget \
        zlib-devel \
        rpm-build

    # Install requested compiler
    case "${COMPILER:-gcc}" in
        gcc) ;;  # default gcc already installed
        gcc14)
            dnf install -y gcc14 gcc14-c++
            ;;
        clang|clang15)
            dnf install -y clang
            ;;
        clang18)
            dnf install -y clang18
            ;;
        clang19)
            dnf install -y clang19
            ;;
        clang20)
            dnf install -y clang20
            ;;
    esac
}

function ubuntu_dependencies() {
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
        autoconf \
        automake \
        bc \
        build-essential \
        cmake \
        git-core \
        libfreetype6-dev \
        libtool \
        ninja-build \
        pkg-config \
        texinfo \
        wget \
        yasm \
        zlib1g-dev \
        libnuma-dev \
        nasm \
        python3-pip \
        dpkg-dev \
        fakeroot

    # Install requested compiler
    case "${COMPILER:-gcc}" in
        gcc) ;;  # build-essential provides default gcc
        gcc[0-9]*)
            ver="${COMPILER#gcc}"
            apt-get install -y gcc-${ver} g++-${ver}
            ;;
        clang|clang[0-9]*)
            ver="${COMPILER#clang}"
            apt-get install -y clang${ver:+-$ver}
            ;;
    esac
}

os_name=$(cat /etc/os-release | grep "PRETTY_NAME" | awk -F"=" '{print $2}' | tr -d '[="=]' | tr -d [:cntrl:])

if [[ $(echo $os_name | grep -i "amazon") != "" ]]; then
    amazon_linux_2023_dependencies
elif [[ "$os_name" =~ "Ubuntu" ]]; then
    ubuntu_dependencies
else
    echo "$os_name not supported"
    exit 1
fi
