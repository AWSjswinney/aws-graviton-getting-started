#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}"

ntasks=$(python3 -c "print($(nproc) * 2)")
parallelism=$(python3 -c "print($(nproc) // 2)")
echo "x264 test..."
rm -rf output/ && ./parallel-benchmark.py --parallelism ${parallelism} --ntasks ${ntasks} --shell --output "output" -c "./x264-test-multires.sh %n"

ntasks=$(python3 -c "print($(nproc) * 1)")
parallelism=$(python3 -c "print($(nproc) // 4)")
echo "x265 test..."
rm -rf output/ && ./parallel-benchmark.py --parallelism ${parallelism} --ntasks ${ntasks} --shell --output "output" -c "./x265-test-multires.sh %n"
