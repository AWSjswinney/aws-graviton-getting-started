#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PATH=$PATH:$(realpath "${SCRIPT_DIR}"/../install/bin)
