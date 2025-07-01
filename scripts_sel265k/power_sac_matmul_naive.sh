#!/bin/bash

ITER=20

make bin/matmul_naive_mt || exit 1

mkdir -p results_sel265k

bench()
{
    threads=$1
    size=$2
    power=$3
    bg=$4

    echo $power > /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw
    echo $power > /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw

    # Warmup
    numactl --interleave all -C 0-$(($threads-1)) ./bin/matmul_naive_mt -mt $threads 1 $size > /dev/null

    numactl --interleave all -C 0-$(($threads-1)) ./bin/matmul_naive_mt -mt $threads $ITER $size \
        | awk -v size=$size -v threads=$threads -v powercap=$power -v bg=$bg '{
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
        }' >> "results_sel265k/power_sac_matmul_naive.csv"
}

for threads in 1 8; do
  for size in 1500 3000; do
    for power in {12500000..125000000..12500000}; do
      bench $threads $size $power 0
    done
  done
done

# With background load of 4 threads, on any of the 8 performance cores
stress-ng -c 4 --taskset 0-7 &

for size in 1500 3000; do
  for power in {12500000..125000000..12500000}; do
    bench 8 $size $power 4
  done
done

killall stress-ng
