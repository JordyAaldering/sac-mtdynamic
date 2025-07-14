#!/bin/bash

. ./scripts_sel265k/bench.sh

(
cd rust
cargo build --release
)

for threads in 8; do
  for size in 5000 15000; do
    bench_range rust_stencil rust/target/release/stencil $threads $size 0
  done
done

stress-ng -c 4 --taskset 0-7 &
sleep 1

for size in 5000 15000; do
  bench_range rust_stencil rust/target/release/stencil 8 $size 4
done

killall stress-ng
sleep 1
