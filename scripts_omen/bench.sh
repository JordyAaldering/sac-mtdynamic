#!/bin/bash

ITER=${ITER:-20}

mkdir -p results_omen

bench()
{
  name=$1
  bin=$2
  threads=$3
  size=$4
  power=$5
  bg=$6

  echo $power > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
  echo $power > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
  echo $power > /sys/class/powercap/intel-rapl-mmio:0/constraint_0_power_limit_uw
  echo $power > /sys/class/powercap/intel-rapl-mmio:0/constraint_1_power_limit_uw

  # Warmup
  numactl --interleave all -C 0,2,4,6 ./$bin -mt $threads 5 $size > /dev/null

  numactl --interleave all -C 0,2,4,6 ./$bin -mt $threads $ITER $size \
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
    }' >> "results_omen/$name.csv"
}

bench_range()
{
  name=$1
  bin=$2
  threads=$3
  size=$4
  bg=$5

  printf "%d %d" $threads $size
  for power in {4500000..45000000..4500000}; do
    bench $name $bin $threads $size $power $bg
    printf "."
  done
  printf "\n"
}
