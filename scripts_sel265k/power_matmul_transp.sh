#!/bin/bash

ITER=20

make bin/matmul_mt || exit 1

mkdir -p results_sel265k

bench()
{
    threads=$1
    size=$2
    power=$3

    echo $power > /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw
    echo $power > /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw

    numactl -C 0-$(($threads-1)) ./bin/matmul_mt -mt $threads $ITER $size \
        | awk -v size=$size -v threads=$threads -v powercap=$power '{
            wl_idx = (NR - 1) % 2;
            for (i = 3; i <= NF; i++) {
                b[wl_idx,i] = a[wl_idx,i] + ($i - a[wl_idx,i]) / (NR / 2.0);
                q[wl_idx,i] += ($i - a[wl_idx,i]) * ($i - b[wl_idx,i]);
                a[wl_idx,i] = b[wl_idx,i];
            }
        } END {
            printf "transp %d %d %d", size, threads, powercap;
            for (i = 3; i <= NF; i++) {
                printf " %f %f", a[0,i], sqrt(q[0,i] / (NR / 2.0));
            }
            print "";
            printf "matmul %d %d %d", size, threads, powercap;
            for (i = 3; i <= NF; i++) {
                printf " %f %f", a[1,i], sqrt(q[1,i] / (NR / 2.0));
            }
            print "";
        }' >> "results_sel265k/power_matmul_transp.csv"
}

for threads in 1 8; do
  stress --cpu 20 --timeout 60
  for size in 1000 2000; do
    for power in {12500000..125000000..12500000}; do
      bench $threads $size $power
    done
  done
done
