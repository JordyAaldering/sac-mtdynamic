#!/bin/bash

. ./scripts_omen/bench.sh

(
cd rust
cargo build --release
)

for threads in 4; do
  for size in 2048 4096; do
    bench_range rust_flash rust/target/release/flash $threads $size 0
  done
done

stress-ng -c 2 --taskset 0,2,4,6 &
sleep 1

for size in 2048 4096; do
  bench_range rust_flash rust/target/release/flash 4 $size 2
done

killall stress-ng
sleep 1
