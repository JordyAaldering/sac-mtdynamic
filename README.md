## Building the image

```
docker build -t mtdynamic .
```

## Running the image mounted to the local filesystem

```
docker run -it --rm --name=mtdynamic \
    --mount type=bind,source=${PWD},target=/home/ubuntu/ \
    --mount type=bind,source=/sys/class/powercap/intel-rapl,target=/sys/class/powercap/intel-rapl \
    --privileged \
    mtdynamic
```

Then within this container, the benchmarking scripts can be run.
