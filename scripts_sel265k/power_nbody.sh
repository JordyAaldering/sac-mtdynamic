#!/bin/bash

if [ "$#" -ne 2 ]; then
    printf "Usage: %s <iter> <size> <outdir>\n" "$0" >&2
    printf "\t<iter>: number of times to repeat the experiment\n" >&2
    printf "\t<size>: input number of elements\n" >&2
    exit 1
fi

iter=$1
size=$2

make bin/nbody_mt || exit 1

mkdir -p results_sel265k

bench()
{
    echo $2 > /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw
    echo $2 > /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw

    numactl -C 0-$(($1-1)) ./bin/nbody_mt -mt $1 $iter $size \
        | awk -v size=$size -v threads=$1 -v powercap=$2 '{
            for (i = 3; i <= NF; i++) {
                b[i] = a[i] + ($i - a[i]) / NR;
                q[i] += ($i - a[i]) * ($i - b[i]);
                a[i] = b[i];
            }
        } END {
            printf "nbody,%d,%d,%d", size, threads, powercap;
            for (i = 3; i <= NF; i++) {
                printf ",%f,%f", a[i], sqrt(q[i] / NR);
            }
            print "";
        }' >> "results_sel265k/nbody.csv"
}

for t in 1 8 20; do
    for w in 10000000 15000000 25000000 35000000 45000000 55000000 65000000 75000000 100000000 125000000; do
        bench $t $w
    done
done
