#!/bin/bash

if [ "$#" -ne 6 ]; then
    printf "Usage: %s <outfile> <binary> <size> <threads> <taskset> <powercap>\n" "$0" >&2
    printf "\t<outfile>:  output file, e.g. 'results/rust_flash.csv'\n" >&2
    printf "\t<binary>:   the executable, e.g. 'rust/target/release/flash'\n" >&2
    printf "\t<size>:     input problem size, e.g. '1500'\n" >&2
    printf "\t<threads>:  maximum number of threads, e.g. '4'\n" >&2
    printf "\t<taskset>:  processor ids to pin to, e.g. '0,2,4,8'\n" >&2
    printf "\t<powercap>: maximum power limit, e.g. '125000000'\n" >&2
    exit 1
fi

OUT=$1
BIN=$2
SIZE=$3
THREADS=$4
TASKSET=$5
POWERCAP=$6

ITER=${ITER:-20}

(
cd rust
cargo build --release
)

make bin/nbody_mtd || exit 1

bench_()
{
  threads=$1
  size=$2
  power=$3
  bg=$4

  echo $power > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
  echo $power > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw

  # Warmup
  numactl --interleave all -C $TASKSET ./$BIN -mt $threads 5 $size > /dev/null

  numactl --interleave all -C $TASKSET ./$BIN -mt $threads $ITER $size \
    | awk -v threads=$threads -v size=$size -v power=$power -v bg=$bg '{
      for (i = 2; i <= NF; i++) {
        b[i] = a[i] + ($i - a[i]) / NR;
        q[i] += ($i - a[i]) * ($i - b[i]);
        a[i] = b[i];
      }
    } END {
      printf "%d %d %d %d", threads, size, power, bg;
      for (i = 2; i <= NF; i++) {
        printf " %f %f", a[i], sqrt(q[i] / NR);
      }
      print "";
    }' >> $OUT
}

bench()
{
  size=$1

  for threads in $THREADS; do
    for pct in {10..100..10}; do
      power=$(($POWERCAP*$pct/100))
      bg=0
      bench_ $threads $size $power $bg
      printf "."
    done
    printf "\n"
  done

  stress-ng -c 4 --taskset 0-7 &
  sleep 1

  for threads in $THREADS; do
    for pct in {10..100..10}; do
      power=$(($POWERCAP*$pct/100))
      bg=$(($THREADS/2))
      bench_ $threads $size $power $bg
      printf "."
    done
    printf "\n"
  done

  killall stress-ng
  sleep 1
}

bench $SIZE
