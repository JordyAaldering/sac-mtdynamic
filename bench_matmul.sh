#!/bin/bash

#SBATCH --account=csmpi
#SBATCH --partition=csmpi_long
#SBATCH --nodelist=cn125
#SBATCH --mem=0
#SBATCH --cpus-per-task=16
#SBATCH --time=1:00:00
#SBATCH --output=bench_matmul.out

if [ "$#" -ne 2 ]; then
    printf "Usage: %s <iter> <size>\n" "$0" >&2
    printf "\t<iter>: number of times to repeat the experiment\n" >&2
    printf "\t<size>: input matrix size\n" >&2
    exit 1
fi

iter=$1
size=$2

make clean
make bin/matmul_mtd || exit 1

../mtdynamic/target/release/server \
    --single \
    --letterbox-size 20 \
    --runtime-cutoff 0.01 \
    genetic \
        --score pareto \
        --survival-rate 0.75 \
        --mutation-rate 0.25 \
        --immigration-rate 0.0 &
sleep 2 # Wait for the server to be running
./bin/matmul_mtd -mt 16 $iter $size
