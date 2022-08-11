#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
set -u

if [[ $(id -u) -ne 0 ]]; then
    echo "Must run with root privileges"
    exit 1
fi

function amazon_linux_2_dependencies() {
yum install -y \
        autoconf \
        automake \
        bzip2 \
        bzip2-devel \
        cmake3 \
        freetype-devel \
        gcc \
        gcc-c++ \
        git \
        libtool \
        make \
        pkgconfig \
        python3-pip \
        nasm \
        zlib-devel

ln -s cmake3 /usr/bin/cmake
}
function amazon_linux_2_gcc10 {
yum install -y \
        gcc10 \
        gcc10-c++ \
        gcc10-binutils

echo "To use gcc 10 for building, export the following environment variables:"
echo "export CC=/usr/bin/gcc10-cc"
echo "export CXX=/usr/bin/gcc10-c++"
echo "export LD=/usr/bin/gcc10-gcc"
}

function ubuntu_dependencies() {
apt-get update && apt-get -y install \
        autoconf \
        automake \
        build-essential \
        cmake \
        git-core \
        libass-dev \
        libfreetype6-dev \
        libgnutls28-dev \
        libsdl2-dev \
        libtool \
        libva-dev \
        libvdpau-dev \
        libvorbis-dev \
        libxcb1-dev \
        libxcb-shm0-dev \
        libxcb-xfixes0-dev \
        pkg-config \
        texinfo \
        wget \
        yasm \
        zlib1g-dev \
        libnuma-dev \
        nasm \
        libmp3lame-dev \
        python3-pip
}

os_name=$(cat /etc/os-release | grep "PRETTY_NAME" | awk -F"=" '{print $2}' | tr -d '[="=]' | tr -d [:cntrl:])
if [[ "$os_name" == "Amazon Linux 2" ]]; then
    amazon_linux_2_dependencies
    # install gcc10
    amazon_linux_2_gcc10
elif [[ "$os_name" =~ "Ubuntu 22.04" ]]; then
    ubuntu_dependencies
else
    echo "$os_name not supported"
    exit 1
fi
