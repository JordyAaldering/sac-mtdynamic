#!/bin/bash

if [ "$#" -ne 3 ]; then
    printf "Usage: %s <iter> <size> <outdir>\n" "$0" >&2
    printf "\t<iter>: number of times to repeat the experiment\n" >&2
    printf "\t<d>: head dimension\n" >&2
    printf "\t<n>: sequence length\n" >&2
    exit 1
fi

iter=$1
d=$2
n=$3

make bin/flash_seq || exit 1
make bin/flash_mt || exit 1

mkdir -p results_sel265k

bench_seq()
{
    echo $1 > /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw
    echo $1 > /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw

    ./bin/flash_seq $iter $d $n \
        | awk -v size=$(($d * $n)) -v threads=1 -v powercap=$1 '{
            for (i = 3; i <= NF; i++) {
                b[i] = a[i] + ($i - a[i]) / NR;
                q[i] += ($i - a[i]) * ($i - b[i]);
                a[i] = b[i];
            }
        } END {
            printf "flash,%d,%d,%d", size, threads, powercap;
            for (i = 3; i <= NF; i++) {
                printf ",%f,%f", a[i], sqrt(q[i] / NR);
            }
            print "";
        }' >> "results_sel265k/flash.csv"
}

bench()
{
    echo $2 > /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw
    echo $2 > /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw

    numactl -C 0-$(($1-1)) ./bin/flash_mt -mt $1 $iter $d $n \
        | awk -v size=$(($d * $n)) -v threads=$1 -v powercap=$2 '{
            for (i = 3; i <= NF; i++) {
                b[i] = a[i] + ($i - a[i]) / NR;
                q[i] += ($i - a[i]) * ($i - b[i]);
                a[i] = b[i];
            }
        } END {
            printf "flash,%d,%d,%d", size, threads, powercap;
            for (i = 3; i <= NF; i++) {
                printf ",%f,%f", a[i], sqrt(q[i] / NR);
            }
            print "";
        }' >> "results_sel265k/flash.csv"
}

# Sequential
bench_seq  15000000
bench_seq  25000000
bench_seq  35000000
bench_seq  45000000
bench_seq  55000000
bench_seq  65000000
bench_seq  75000000
bench_seq 100000000
bench_seq 125000000

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
