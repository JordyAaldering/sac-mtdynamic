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
stress --cpu 20 --timeout 10
# sleep 1 # Wait for the server to be running
numactl -C 0-7 ./bin/nbody_mtd -mt 8 $iter $size
