#!/bin/bash

ITER=${ITER:-20}

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

  # Warmup
  numactl --interleave all -C 0-$(($threads-1)) ./$bin -mt $threads 5 $size > /dev/null

  numactl --interleave all -C 0-$(($threads-1)) ./$bin -mt $threads $ITER $size \
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
    }' >> "results_sel265k/$name.csv"
}

bench_range()
{
  bin=$1
  threads=$2
  size=$3
  bg=$4

  printf "%d %d" $threads $size
  for power in {12500000..125000000..12500000}; do
    bench $bin $threads $size $power $bg
    printf "."
  done
  printf "\n"
}
