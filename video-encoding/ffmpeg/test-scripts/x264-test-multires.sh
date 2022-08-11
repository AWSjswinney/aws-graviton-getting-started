#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "${SCRIPT_DIR}"/env.sh

cd "${SCRIPT_DIR}"

set -eux
mkdir -p output

output_num=${1:-0}

common_options="-c:v libx264 -x264opts keyint=2:no-scenecut -profile:v main -c:a aac -sws_flags bicubic -hls_list_size 1 -strict -2"
output_name=output/bbb-scene

ffmpeg \
    -re \
    -hide_banner -y -vsync vfr \
    -i video-samples/Big_Buck_Bunny_1080_10s_30MB.mp4 \
        ${common_options} -s 1280x720 -r 30 -b:v 2100k ${output_name}-720p30_${output_num}.mp4 \
        ${common_options} -s 852x480  -r 30 -b:v 1200k ${output_name}-480p30_${output_num}.mp4 \
        ${common_options} -s 640x360  -r 30 -b:v 1000k ${output_name}-360p30_${output_num}.mp4 \
        ${common_options} -s 284x160  -r 30 -b:v 1000k ${output_name}-160p30_${output_num}.mp4
