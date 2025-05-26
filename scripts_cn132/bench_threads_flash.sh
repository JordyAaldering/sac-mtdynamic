#!/bin/bash

#SBATCH --account=csmpi
#SBATCH --partition=csmpi_fpga_long
#SBATCH --nodelist=cn132
#SBATCH --mem=0
#SBATCH --cpus-per-task=32
#SBATCH --time=1:00:00
#SBATCH --output=bench_threads_flash.out

if [ "$#" -ne 4 ]; then
    printf "Usage: %s <iter> <d> <n>\n" "$0" >&2
    printf "\t<iter>: number of times to repeat the experiment\n" >&2
    printf "\t<d>: head dimension\n" >&2
    printf "\t<n>: sequence length\n" >&2
    printf '\t<outdir>: directory to store results\n' >&2
    exit 1
fi

iter=$1
d=$2
n=$3
outdir=$4

mkdir -p $outdir

make clean
make bin/flash_mt || exit 1

bench()
{
    numactl --interleave all ./bin/flash_mt -mt $1 $iter $d $n \
        | awk -v threads=$1 -v size=$(($d * $n)) '{
            for (i = 2; i <= NF; i++) {
                b[i] = a[i] + ($i - a[i]) / NR;
                q[i] += ($i - a[i]) * ($i - b[i]);
                a[i] = b[i];
            }
        } END {
            printf "flash,%d,%d", size, threads;
            for (i = 2; i <= NF; i++) {
                printf ",%f,%f", a[i], sqrt(q[i] / NR);
            }
            print "";
        }' >> "${outdir}/flash.csv"
}

bench 1
bench 2
bench 4
bench 8
bench 16
bench 32
