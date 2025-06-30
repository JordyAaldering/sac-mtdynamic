#!/bin/bash

ITER=20

(
cd src_rust
cargo build --release
)

mkdir -p results_sel265k

bench()
{
    threads=$1
    size=$2
    power=$3

    echo $power > /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw
    echo $power > /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw

    # Warmup
    numactl -C 0-$(($threads-1)) ./src_rust/target/release/nbody 1 $size $threads > /dev/null

    numactl -C 0-$(($threads-1)) ./src_rust/target/release/nbody $ITER $size $threads \
        | awk -v size=$size -v threads=$threads -v powercap=$power '{
            for (i = 2; i <= NF; i++) {
                b[i] = a[i] + ($i - a[i]) / NR;
                q[i] += ($i - a[i]) * ($i - b[i]);
                a[i] = b[i];
            }
        } END {
            printf "%d %d %d", size, threads, powercap;
            for (i = 2; i <= NF; i++) {
                printf " %f %f", a[i], sqrt(q[i] / NR);
            }
            print "";
        }' >> "results_sel265k/power_rust_nbody.csv"
}

for threads in 1 8; do
  for size in 5000 10000; do
    printf "%d %d" $threads $size
    for power in {12500000..125000000..12500000}; do
      bench $threads $size $power
      printf "."
    done
    printf "\n"
  done
done
