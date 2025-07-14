#!/bin/bash

. ./scripts_sel265k/bench.sh

make bin/matmul_naive_mt || exit 1

for threads in 1 8; do
  for size in 500 1500; do
    bench_range sac_matmul_naive bin/matmul_naive_mt $threads $size 0
  done
done

stress-ng -c 4 --taskset 0-7 &
sleep 1

for size in 500 1500; do
  bench_range sac_matmul_naive bin/matmul_naive_mt 8 $size 4
done

killall stress-ng
sleep 1
