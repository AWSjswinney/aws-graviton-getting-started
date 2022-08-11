#!/usr/bin/env python3

import os
import time
import argparse
import itertools
import subprocess
import multiprocessing

import tqdm

def main():
    parser = argparse.ArgumentParser(description="Run the same test many time in parallel")
    parser.add_argument('-p', '--parallelism', type=int, help='how many tasks to run in parallel')
    parser.add_argument('-n', '--ntasks', type=int, help='total number of tasks to run')
    parser.add_argument('-c', '--command', type=str, help='command string to execute')
    parser.add_argument('-s', '--shell', action='store_true', help='use sh to execute the command')
    parser.add_argument('-o', '--output', type=str, help='specify an output directory for sending command output', default='output')

    args = parser.parse_args()
    try:
        os.mkdir(args.output)
    except FileExistsError:
        pass

    pool = multiprocessing.Pool(args.parallelism, maxtasksperchild=None)
    jobs = job_iterator(args.command, args.shell, args.ntasks, args.output)
    start = time.time()
    for _ in tqdm.tqdm(pool.imap_unordered(execute, jobs), total=args.ntasks):
        pass
    end = time.time()
    print(f"Tasks completed in {end-start} seconds")

def job_iterator(command, use_shell, n, output_prefix):
    for i in range(n):
        yield (i, command, use_shell, output_prefix)

def execute(arg):
    execute_(*arg)

def execute_(i, command, use_shell, output_prefix):
    command = command.replace('%n', f'{i:03d}')
    with open(f'{output_prefix}/out-{i:03d}.log', 'w') as f:
        subprocess.run(command, shell=use_shell, stdout=f, stderr=f, stdin=subprocess.DEVNULL)
if __name__ == '__main__':
    main()
