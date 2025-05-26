#!/bin/bash

#SBATCH --account=csmpi
#SBATCH --partition=csmpi_fpga_long
#SBATCH --nodelist=cn132
#SBATCH --mem=0
#SBATCH --cpus-per-task=32
#SBATCH --time=1:00:00
#SBATCH --output=bench_threads_matmul.out

if [ "$#" -ne 2 ]; then
    printf "Usage: %s <iter> <size>\n" "$0" >&2
    printf "\t<iter>: number of times to repeat the experiment\n" >&2
    printf "\t<size>: input matrix size\n" >&2
    exit 1
fi

iter=$1
size=$2

make clean
make bin/matmul_mt || exit 1

mkdir -p results_sel265k

bench()
{
    echo $1 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
    numactl --interleave all ./bin/matmul_mt -mt 8 $iter $size \
        | awk -v size=$size '{
            wl_idx = (NR - 1) % 2;
            for (i = 2; i <= NF; i++) {
                b[wl_idx,i] = a[wl_idx,i] + ($i - a[wl_idx,i]) / (NR / 2.0);
                q[wl_idx,i] += ($i - a[wl_idx,i]) * ($i - b[wl_idx,i]);
                a[wl_idx,i] = b[wl_idx,i];
            }
        } END {
            printf "transp,%d", size;
            for (i = 2; i <= NF; i++) {
                printf ",%f,%f", a[0,i], sqrt(q[0,i] / (NR / 2.0));
            }
            print "";
            printf "matmul,%d", size;
            for (i = 2; i <= NF; i++) {
                printf ",%f,%f", a[1,i], sqrt(q[1,i] / (NR / 2.0));
            }
            print "";
        }' >> "results_sel265k/matmul.csv"
}

bench  50000000
bench 100000000
bench 150000000
bench 200000000
# End with the default value
bench 250000000
