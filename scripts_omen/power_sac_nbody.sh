#!/bin/bash

. ./scripts_omen/bench.sh

make bin/nbody_mt || exit 1

for threads in 1 4; do
  for size in 5000 15000; do
    bench_range sac_nbody bin/nbody_mt $threads $size 0
  done
done

stress-ng -c 2 --taskset 0,2,4,6 &
sleep 1

for size in 5000 15000; do
  bench_range sac_nbody bin/nbody_mt 4 $size 2
done

killall stress-ng
sleep 1
