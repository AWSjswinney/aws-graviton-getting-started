#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
set -euxo pipefail

cd "$SCRIPT_DIR"/../patches
sources_path="$(realpath ../sources)"
for dir in */; do
    cd "$sources_path"/"$dir"
    git am "$SCRIPT_DIR"/../patches/"$dir"/*.patch
done
