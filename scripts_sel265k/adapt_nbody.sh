#!/bin/bash

if [ "$#" -ne 2 ]; then
    printf "Usage: %s <iter> <size>\n" "$0" >&2
    printf "\t<iter>: number of times to repeat the experiment\n" >&2
    printf "\t<size>: input matrix size\n" >&2
    exit 1
fi

iter=$1
size=$2

make clean
make bin/nbody_mtd || exit 1

../mtdynamic/target/release/server \
    --once \
    --letterbox-size 20 \
    genetic \
        --score energy \
        --survival-rate 0.75 \
        --mutation-rate 0.25 \
        --immigration-rate 0.0 &
sleep 1 # Wait for the server to be running
numactl -C 0-7 ./bin/nbody_mtd -mt 8 $iter $size
