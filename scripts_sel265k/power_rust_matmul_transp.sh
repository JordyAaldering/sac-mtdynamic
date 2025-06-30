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

    numactl -C 0-$(($threads-1)) ./src_rust/target/release/matmul_transp $ITER $size $threads \
        | awk -v size=$size -v threads=$threads -v powercap=$power '{
            for (i = 2; i <= NF; i++) {
                b[i] = a[i] + ($i - a[i]) / NR;
                q[i] += ($i - a[i]) * ($i - b[i]);
                a[i] = b[i];
            }
        } END {
            printf "matmul %d %d %d", size, threads, powercap;
            for (i = 2; i <= NF; i++) {
                printf " %f %f", a[i], sqrt(q[i] / NR);
            }
            print "";
        }' >> "results_sel265k/power_rust_matmul_transp.csv"
}

for threads in 1 8; do
  #stress --cpu 20 --timeout 60
  for size in 10000 25000; do
    for power in {12500000..125000000..12500000}; do
      bench $threads $size $power
    done
  done
done
