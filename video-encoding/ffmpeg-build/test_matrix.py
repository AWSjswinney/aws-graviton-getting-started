#!/usr/bin/env python3
"""
Test matrix for FFmpeg builder - tests combinations of distros and compilers.
Outputs results in markdown table format.
"""

import platform
import subprocess
import sys
from datetime import datetime

# Test matrix: each distro with representative compilers
TEST_CASES = [
    ("al2023", "gcc"),
    ("al2023", "gcc14"),
    ("al2023", "clang"),
    ("al2023", "clang-latest"),
    ("ubuntu-jammy", "gcc"),
    ("ubuntu-jammy", "clang-latest"),
    ("ubuntu-noble", "gcc"),
    ("ubuntu-noble", "gcc14"),
    ("ubuntu-noble", "clang"),
    ("ubuntu-noble", "clang-latest"),
    ("ubuntu-resolute", "clang-latest"),
]

def run_test(distro, compiler):
    cmd = ["./build_ffmpeg.py", "-d", distro, "-C", compiler, "all"]
    result = subprocess.run(cmd, capture_output=True)
    return result.returncode == 0

def main():
    arch = platform.machine()
    results = []
    start = datetime.now()
    
    print(f"Running tests on {arch}...\n", file=sys.stderr)
    
    for distro, compiler in TEST_CASES:
        print(f"Testing: {distro} + {compiler}...", file=sys.stderr)
        passed = run_test(distro, compiler)
        results.append((distro, compiler, passed))
        status = "PASS" if passed else "FAIL"
        print(f"  {status}", file=sys.stderr)
    
    elapsed = datetime.now() - start
    
    # Output markdown table
    print(f"## Test Results ({arch})")
    print(f"")
    print(f"Generated: {datetime.now().strftime('%Y-%m-%d')} | Duration: {elapsed}")
    print(f"")
    print(f"| Distro | Compiler | Status | Notes |")
    print(f"|--------|----------|--------|-------|")
    for distro, compiler, passed in results:
        status = "✅" if passed else "❌"
        print(f"| {distro} | {compiler} | {status} | |")
    
    passed_count = sum(1 for _, _, p in results if p)
    print(f"")
    print(f"**Summary:** {passed_count}/{len(results)} passed")
    
    if passed_count < len(results):
        sys.exit(1)

if __name__ == "__main__":
    main()
