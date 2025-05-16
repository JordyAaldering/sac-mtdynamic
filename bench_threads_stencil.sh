#!/bin/bash

#SBATCH --account=csmpi
#SBATCH --partition=csmpi_long
#SBATCH --nodelist=cn125
#SBATCH --mem=0
#SBATCH --cpus-per-task=16
#SBATCH --time=4:00:00
#SBATCH --output=bench_threads_stencil.out

if [ "$#" -ne 3 ]; then
    printf "Usage: %s <iter> <size>\n" "$0" >&2
    printf "\t<iter>: number of times to repeat the experiment\n" >&2
    printf "\t<size>: input matrix size\n" >&2
    printf '\t<outdir>: directory to store results\n' >&2
    exit 1
fi

iter="$1"
size="$2"
outdir=$3

mkdir -p $outdir

make bin/stencil_mt || exit 1

bench()
{
    numactl --interleave all -C $2 ./bin/stencil_mt -mt $1 $iter $size \
        | awk -v threads=$1 -v size=$size '{
            wl_idx = (NR - 1) % 2;
            for (i = 2; i <= NF; i++) {
                b[wl_idx,i] = a[wl_idx,i] + ($i - a[wl_idx,i]) / (NR / 2.0);
                q[wl_idx,i] += ($i - a[wl_idx,i]) * ($i - b[wl_idx,i]);
                a[wl_idx,i] = b[wl_idx,i];
            }
        } END {
            printf "transp,%d,%2d", size, threads;
            for (i = 2; i <= NF; i++) {
                printf ",%f,%f", a[0,i], sqrt(q[0,i] / (NR / 2.0));
            }
            print "";
            printf "stencil,%d,%2d", size, threads;
            for (i = 2; i <= NF; i++) {
                printf ",%f,%f", a[1,i], sqrt(q[1,i] / (NR / 2.0));
            }
            print "";
        }' >> "${outdir}/stencil.csv"
}

bench  1 "0"
bench  2 "0,8"
bench  4 "0,4,8,12"
bench  8 "0,2,4,6,8,10,12,14"
bench 16 "0-15"
