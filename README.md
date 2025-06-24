## Building the container and removing outdated dangling versions

```
docker build --no-cache -t mtdynamic .
docker image prune
```

## Running the container mounted to the local filesystem

```
docker run -it --rm --name=mtdynamic \
    --mount type=bind,source=${PWD},target=/home/ubuntu \
    --mount type=bind,source=/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0,target=/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0 \
    mtdynamic
```
