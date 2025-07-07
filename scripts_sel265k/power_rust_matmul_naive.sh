#!/bin/bash

. ./scripts_sel265k/bench.sh

(
cd rust
cargo build --release
)

mkdir -p results_sel265k

for threads in 8; do
  for size in 500 1500; do
    bench_range rust_matmul_naive rust/target/release/matmul_naive $threads $size 0
  done
done

# With background load of 4 threads, on any of the 8 performance cores
stress-ng -c 4 --taskset 0-7 &
sleep 1

for size in 500 1500; do
  bench_range rust_matmul_naive rust/target/release/matmul_naive 8 $size 4
done

killall stress-ng
sleep 1
