#!/bin/bash

#SBATCH --account=csmpi
#SBATCH --partition=csmpi_long
#SBATCH --nodelist=cn125
#SBATCH --mem=0
#SBATCH --cpus-per-task=16
#SBATCH --time=1:00:00
#SBATCH --output=bench_threads_nbody.out

if [ "$#" -ne 2 ]; then
    printf "Usage: %s <iter> <size>\n" "$0" >&2
    printf "\t<iter>: number of times to repeat the experiment\n" >&2
    printf "\t<size>: input matrix size\n" >&2
    exit 1
fi

iter="$1"
size="$2"

make bin/nbody_mt || exit 1

./start_server/genetic.sh & ./bin/nbody_mt -mt 16 $iter $size
