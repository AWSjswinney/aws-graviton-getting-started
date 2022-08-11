#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
set -euxo pipefail

cd "$SCRIPT_DIR"/../
mkdir -p sources
cd sources

git clone https://git.ffmpeg.org/ffmpeg.git
git clone https://code.videolan.org/videolan/x264.git
git clone https://bitbucket.org/multicoreware/x265_git x265
