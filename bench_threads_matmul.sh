#!/bin/bash

#SBATCH --account=csmpi
#SBATCH --partition=csmpi_long
#SBATCH --nodelist=cn125
#SBATCH --mem=0
#SBATCH --cpus-per-task=16
#SBATCH --time=4:00:00
#SBATCH --output=bench_threads_matmul.out

if [ "$#" -ne 3 ]; then
    printf "Usage: %s <name> <iter> <size>\n" "$0" >&2
    printf "\t<name>: job name ['laptop', 'cn125', 'cn132']\n" >&2
    printf "\t<iter>: number of times to repeat the experiment\n" >&2
    printf "\t<size>: input matrix size\n" >&2
    exit 1
fi

name="$1"
iter="$2"
size="$3"

mkdir -p $name

make bin/matmul_mt || exit 1

bench_numa()
{
    ./start_server/fixed.sh $name/matmul_fixed_"$size"_$1.csv &
    sleep 1 # ensure that the server is running
    numactl --interleave all ./bin/matmul_mt -mt $1 $iter $size
}

bench_bind()
{
    ./start_server/fixed.sh $name/matmul_fixed_"$size"_$1.csv &
    sleep 1 # ensure that the server is running
    numactl -C 0-15 ./bin/matmul_mt -mt $1 $iter $size
}

bench_numa 1
bench_numa 2
bench_numa 4
bench_numa 8
bench_bind 16
