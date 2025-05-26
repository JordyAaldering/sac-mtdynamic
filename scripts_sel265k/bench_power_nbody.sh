#!/bin/bash

if [ "$#" -ne 2 ]; then
    printf "Usage: %s <iter> <size> <outdir>\n" "$0" >&2
    printf "\t<iter>: number of times to repeat the experiment\n" >&2
    printf "\t<size>: input number of elements\n" >&2
    exit 1
fi

iter=$1
size=$2

make clean
make bin/nbody_mt || exit 1

mkdir -p results_sel265k

bench()
{
    echo $1 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
    echo $1 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw

    numactl --interleave all ./bin/nbody_mt -mt 8 $iter $size \
        | awk -v size=$size '{
            for (i = 1; i <= NF; i++) {
                b[i] = a[i] + ($i - a[i]) / NR;
                q[i] += ($i - a[i]) * ($i - b[i]);
                a[i] = b[i];
            }
        } END {
            printf "nbody,%d", size;
            for (i = 1; i <= NF; i++) {
                printf ",%f,%f", a[i], sqrt(q[i] / NR);
            }
            print "";
        }' >> "results_sel265k/nbody.csv"
}

bench  50000000
bench 100000000
bench 150000000
bench 200000000
# End with the default value
bench 250000000
