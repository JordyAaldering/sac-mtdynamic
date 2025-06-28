#!/bin/bash

if [ "$#" -ne 2 ]; then
    printf "Usage: %s <iter> <size> <outdir>\n" "$0" >&2
    printf "\t<iter>: number of times to repeat the experiment\n" >&2
    printf "\t<size>: input number of elements\n" >&2
    exit 1
fi

iter=$1
size=$2

make bin/matmul_naive_mt || exit 1

mkdir -p results_sel265k

bench()
{
    echo $2 > /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw
    echo $2 > /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw

    numactl -C 0-$(($1-1)) ./bin/matmul_naive_mt -mt $1 $iter $size \
        | awk -v size=$size -v threads=$1 -v powercap=$2 '{
            for (i = 3; i <= NF; i++) {
                b[i] = a[i] + ($i - a[i]) / NR;
                q[i] += ($i - a[i]) * ($i - b[i]);
                a[i] = b[i];
            }
        } END {
            printf "matmul_naive,%d,%d,%d", size, threads, powercap;
            for (i = 3; i <= NF; i++) {
                printf ",%f,%f", a[i], sqrt(q[i] / NR);
            }
            print "";
        }' >> "results_sel265k/matmul_naive.csv"
}

# Use only performance cores
bench 8  15000000
bench 8  25000000
bench 8  35000000
bench 8  45000000
bench 8  55000000
bench 8  65000000
bench 8  75000000
bench 8 100000000
bench 8 125000000

# Use both performance and efficiency cores
bench 20  15000000
bench 20  25000000
bench 20  35000000
bench 20  45000000
bench 20  55000000
bench 20  65000000
bench 20  75000000
bench 20 100000000
bench 20 125000000
