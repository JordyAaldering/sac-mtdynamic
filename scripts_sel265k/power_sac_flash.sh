#!/bin/bash

ITER=20
HEAD_DIM=64

make bin/flash_mt || exit 1

mkdir -p results_sel265k

bench()
{
    threads=$1
    sequence_length=$2
    power=$3

    echo $power > /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw
    echo $power > /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw

    # Warmup
    numactl -C 0-$(($threads-1)) ./bin/flash_mt -mt $threads 1 $size > /dev/null

    numactl -C 0-$(($threads-1)) ./bin/flash_mt -mt $threads $ITER $HEAD_DIM $sequence_length \
        | awk -v size=$sequence_length -v threads=$threads -v powercap=$power '{
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
        }' >> "results_sel265k/power_sac_flash.csv"
}

for threads in 1 8; do
  for sequence_length in 1024 8192; do
    for power in {12500000..125000000..12500000}; do
      bench $threads $sequence_length $power
    done
  done
done
