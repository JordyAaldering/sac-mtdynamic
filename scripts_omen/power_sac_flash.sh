#!/bin/bash

ITER=50

. ./scripts_omen/bench.sh

make bin/flash_mt || exit 1

mkdir -p results_omen

for threads in 1 4; do
  for size in 2048 4096; do
    bench_range sac_flash bin/flash_mt $threads $size 0
  done
done

# With background load of 4 threads, on any of the 8 performance cores
stress-ng -c 2 --taskset 0,2,4,6 &
sleep 1

for size in 2048 4096; do
  bench_range sac_flash bin/flash_mt 4 $size 2
done

killall stress-ng
sleep 1
