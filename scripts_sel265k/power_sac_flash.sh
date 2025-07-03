#!/bin/bash

ITER=50

. ./scripts_sel265k/bench.sh

make bin/flash_mt || exit 1

mkdir -p results_sel265k

for threads in 1 8; do
  for size in 2048 4096; do
    bench_range bin/flash_mt $threads $size 0
  done
done

# With background load of 4 threads, on any of the 8 performance cores
stress-ng -c 4 --taskset 0-7 &
sleep 1

for size in 2048 4096; do
  bench_range bin/flash_mt 8 $size 4
done

killall stress-ng
sleep 1
