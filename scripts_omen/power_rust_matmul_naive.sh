#!/bin/bash

. ./scripts_omen/bench.sh

(
cd rust
cargo build --release
)

mkdir -p results_omen

for threads in 4; do
  for size in 500 1500; do
    bench_range rust_matmul_naive rust/target/release/matmul_naive $threads $size 0
  done
done

# With background load of 4 threads, on any of the 8 performance cores
stress-ng -c 2 --taskset 0,2,4,6 &
sleep 1

for size in 500 1500; do
  bench_range rust_matmul_naive rust/target/release/matmul_naive 4 $size 2
done

killall stress-ng
sleep 1
