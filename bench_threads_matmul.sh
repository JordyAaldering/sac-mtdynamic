#!/bin/bash

#SBATCH --account=csmpi
#SBATCH --partition=csmpi_long
#SBATCH --nodelist=cn125
#SBATCH --mem=0
#SBATCH --cpus-per-task=16
#SBATCH --time=4:00:00
#SBATCH --output=bench_threads_matmul.out

if [ "$#" -ne 2 ]; then
    printf "Usage: %s <iter> <size>\n" "$0" >&2
    printf "\t<iter>: number of times to repeat the experiment\n" >&2
    printf "\t<size>: input matrix size\n" >&2
    exit 1
fi

name="$1"
iter="$2"
size="$3"

mkdir -p $name

make bin/matmul_mt || exit 1

bench()
{
    ./start_server/fixed.sh &
    sleep 1 # ensure that the server is running
    numactl --interleave all -C $2 ./bin/matmul_mt -mt $1 $iter $size
}

bench  1 "0"
bench  2 "0,8"
bench  4 "0,4,8,12"
bench  8 "0,2,4,6,8,10,12,14"
bench 16 "0-15"
