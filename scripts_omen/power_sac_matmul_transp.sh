#!/bin/bash

. ./scripts_omen/bench.sh

make bin/matmul_transp_mt || exit 1

mkdir -p results_omen

for threads in 4; do
  for size in 500 1500; do
    bench_range sac_matmul_transp bin/matmul_transp_mt $threads $size 0
  done
done

# With background load of 4 threads, on any of the 8 performance cores
stress-ng -c 2 --taskset 0,2,4,6 &
sleep 1

for size in 500 1500; do
  bench_range sac_matmul_transp bin/matmul_transp_mt 4 $size 2
done

killall stress-ng
sleep 1
