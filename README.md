## Building the container

```
docker build -t mtdynamic .
```

## Running the container mounted to the local filesystem

```
docker run -it --rm --name=mtdynamic \
    --mount type=bind,source=${PWD},target=/home/ubuntu/ \
    --mount type=bind,source=/sys/class/powercap/intel-rapl,target=/sys/class/powercap/intel-rapl \
    --privileged \
    mtdynamic
```

## Running the benchmarking scripts and closing the container afterwards

```
docker run --rm --name=mtdynamic \
    --mount type=bind,source=${PWD},target=/home/ubuntu/ \
    --mount type=bind,source=/sys/class/powercap/intel-rapl,target=/sys/class/powercap/intel-rapl \
    --privileged \
    mtdynamic \
    ./bench_power_all.sh
```

## Copy output

```
scp jordy@sel-265k:~/sac-mtdynamic/results_sel265k/*.csv results_sel265k
```
