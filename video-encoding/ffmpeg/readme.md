# Optimize FFMPEG for Graviton

In order to get the best performance from ffmpeg on Graviton 2 and Graviton 3, the first step is to ensure you are running an optimized build from the latest code. Amazon engineers and others have made recent contributions to ffmpeg, x264, and x265 to improve performance on Arm64, the architecture of Graviton. Graviton 3 enjoys double the vector bandwidth of Graviton 2 and this translates directly to performance advantages. Every use case for video encoding is different and we encourage you to benchmark your own. In this example, Graviton 2 does not achieve the same speed as c5 instances for h.265, but its lower price allows it to achieve a lower cost per encode job. Graviton 3, with better vector throughput, achieves the fastest execution time and the lowest cost.

|h.264 transcode sample	|c6g.4xl	|c5.4xl	|c7g.4xl	|c6i.4xl	|
|---	|---	|---	|---	|---	|
|execution time (seconds)	|60.3	|63	|44.3	|50.6	|
|instance price per hour	|$0.54	|$0.68	|$0.58	|$0.68	|
|cost / 1000 jobs	|$9.11	|$11.90	|$7.14	|$9.56	|
|h.265 transcode sample	|	|	|	|	|
|execution time (seconds)	|113.0	|102.7	|79.8	|82.8	|
|instance price per hour	|$0.54	|$0.68	|$0.58	|$0.68	|
|cost / 1000 jobs	|$17.08	|$19.40	|$12.86	|$15.64	|

For video on demand type use cases or any use case where video is encoded once asynchronously before it is consumed, you will achieve the best cost efficiency and near the minimum encode time for individual jobs by fully loading your instances. This ensures that you are not paying for unused CPU cycles which could be spent doing work for you. Every use case is different, so testing is essential, but in general you should divide the number of vCPUs by the number of threads each encode job can keep busy and run at least that many parallel jobs. We have also found in testing that you can usually achieve higher overall throughput (and therefore lower cost per frame) by over committing jobs. This comes at the cost of increasing the latency to complete individual jobs, but this may be acceptable for some use cases.

## Building FFMPEG

Clone the latest source from ffmpeg if possible or use the most recently available release branch. There are performance improvements in ffmpeg 4.3, 5.1, and upcoming in 5.2. You can get all completed improvements by building from the tip of the master branch.

We have created some shell scripts for building ffmpeg to jump start your testing with ffmpeg on Graviton. These scripts also work on x86_64 instances. Start an instance with the Amazon Linux 2 AMI or the latest Ubuntu LTS (Jammy, 22.04). The scripts have not been tested on other distributions. The scripts include everything necessary to build ffmpeg starting with a clean instance.

Clone the repositories:

```
./scripts/clone-repos.sh
```

Install build dependencies:

```
sudo ./scripts/install-dependencies.sh
```

Then build the projects:

```
./scripts/build-x264.sh
./scripts/build-x265.sh
./scripts/build-ffmpeg.sh
```

Once this is completed, the binaries are located at `./install/bin`. To rebuild after making changes or applying patches, the easiest way is to use git to clean the source directory and run the build scripts again.

```
git -C sources/x264 clean -fdx
git -C sources/x265 clean -fdx
git -C sources/ffmpeg clean -fdx
```

### Improve Performance Further

For those who want to push the envelope, there are two more things you can do to achieve the maximum performance on Graviton.

1. Use a new version of GCC. The default version of GCC on AL2 is 7, but version 10 is available from the package manager. The script, install-dependencies.sh will do this automatically on AL2. Ubuntu Jammy (22.04) uses GCC version 11.2 which is already sufficiently recent. However to enable gcc 10, you must set environment variables before the build:
    `export CC=/usr/bin/gcc10-cc
    export CXX=/usr/bin/gcc10-c++
    export LD=/usr/bin/gcc10-gcc`
2. Apply a patch to ffmpeg to enable compiler automatic vectorization. The ffmpeg maintainers decided to disable vectorization with `-fno-tree-vectorize` because older versions of GCC would emit buggy code without this disabled. New versions have fixed this, but there are still some edge cases which are problematic with x86_64 inline assembly. This doesn’t affect aarch64 and therefore Graviton, so this patch is safe to apply. 
    `./scripts/apply-exerimental-patches.sh`

## Benchmarking FFMPEG

To aid in benchmarking, we have also included a python script that can be used to benchmark ffmpeg by fully loading the system. There are two included scripts which download a sample video file and execute a basic benchmark using h.264 and h.265. To execute it, first download the test file and then execute the benchmark. The python script is invoked by `benchmark.sh` once for each encoder.

```
./test-scripts/download-test-files.sh
./test-scripts/benchmark.sh
```
