## Building the container and removing outdated dangling versions

```
docker build -t mtdynamic .
docker image prune
```

## Running the container mounted to the local filesystem

```
docker run -it --rm --name=mtdynamic \
    --mount type=bind,source=${PWD},target=/home/ubuntu/sac-mtdynamic \
    --mount type=bind,source=/sys/class/powercap/intel-rapl,target=/sys/class/powercap/intel-rapl \
    --privileged \
    mtdynamic
```
