#!/bin/bash

. ./scripts_sel265k/bench.sh

make bin/stencil_mt || exit 1

for threads in 1 8; do
  for size in 5000 15000; do
    bench_range sac_stencil bin/stencil_mt $threads $size 0
  done
done

stress-ng -c 4 --taskset 0-7 &
sleep 1

for size in 5000 15000; do
  bench_range sac_stencil bin/stencil_mt 8 $size 4
done

killall stress-ng
sleep 1
