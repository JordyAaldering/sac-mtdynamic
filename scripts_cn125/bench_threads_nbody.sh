#!/bin/bash

#SBATCH --account=csmpi
#SBATCH --partition=csmpi_long
#SBATCH --nodelist=cn125
#SBATCH --mem=0
#SBATCH --cpus-per-task=16
#SBATCH --time=1:00:00
#SBATCH --output=bench_threads_nbody.out

if [ "$#" -ne 3 ]; then
    printf "Usage: %s <iter> <size> <outdir>\n" "$0" >&2
    printf "\t<iter>: number of times to repeat the experiment\n" >&2
    printf "\t<size>: input matrix size\n" >&2
    printf '\t<outdir>: directory to store results\n' >&2
    exit 1
fi

iter=$1
size=$2
outdir=$3

mkdir -p $outdir

make clean
make bin/nbody_mt || exit 1

bench()
{
    numactl --interleave all -C $2 ./bin/nbody_mt -mt $1 $iter $size \
        | awk -v threads=$1 -v size=$size '{
            for (i = 2; i <= NF; i++) {
                b[i] = a[i] + ($i - a[i]) / NR;
                q[i] += ($i - a[i]) * ($i - b[i]);
                a[i] = b[i];
            }
        } END {
            printf "nbody,%d,%d", size, threads;
            for (i = 2; i <= NF; i++) {
                printf ",%f,%f", a[i], sqrt(q[i] / NR);
            }
            print "";
        }' >> "${outdir}/nbody.csv"
}

bench 1 "0"
bench 2 "0,8"
bench 4 "0,4,8,12"
bench 8 "0,2,4,6,8,10,12,14"
bench 16 "0-15"
