#!/bin/bash

if [ "$#" -ne 2 ]; then
    printf "Usage: %s <iter> <size>\n" "$0" >&2
    printf "\t<iter>: number of times to repeat the experiment\n" >&2
    printf "\t<size>: input matrix size\n" >&2
    exit 1
fi

iter=$1
size=$2

make bin/nbody_mtd || exit 1

./start_server/genetic.sh &
sleep 1 # Wait for server to be ready
numactl --interleave all -C 0,2,4,6 ./bin/nbody_mtd -mt 4 $iter $size
