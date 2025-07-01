#!/bin/bash

ITER=30
HEAD_DIM=64

(
cd rust
cargo build --release
)

mkdir -p results_sel265k

bench()
{
    threads=$1
    seq_length=$2
    power=$3
    bg=$4

    echo $power > /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw
    echo $power > /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw

    # Warmup
    numactl -C 0-$(($threads-1)) ./rust/target/release/flash 1 $HEAD_DIM $seq_length 1 > /dev/null

    numactl -C 0-$(($threads-1)) ./rust/target/release/flash $ITER $HEAD_DIM $seq_length $threads \
        | awk -v size=$seq_length -v threads=$threads -v powercap=$power -v bg=$bg '{
            for (i = 2; i <= NF; i++) {
                b[i] = a[i] + ($i - a[i]) / NR;
                q[i] += ($i - a[i]) * ($i - b[i]);
                a[i] = b[i];
            }
        } END {
            printf "%d %d %d %d", size, threads, bg, powercap;
            for (i = 2; i <= NF; i++) {
                printf " %f %f", a[i], sqrt(q[i] / NR);
            }
            print "";
        }' >> "results_sel265k/power_rust_flash.csv"
}

for threads in 8; do
  for size in 2048 8192; do
    printf "%d %d" $threads $size
    for power in {12500000..125000000..12500000}; do
      bench $threads $size $power 0
      printf "."
    done
    printf "\n"
  done
done

# With background load of 4 threads, on any of the 8 performance cores
stress-ng -c 4 --taskset 0-7 &

for size in 2048 8192; do
  printf "%d %d" $threads $size
  for power in {12500000..125000000..12500000}; do
    bench 8 $size $power 4
    printf "."
  done
  printf "\n"
done

killall stress-ng
