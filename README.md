## Building the container and removing outdated dangling versions

```
docker build --no-cache -t sac-mtdynamic .
docker image prune
```

## Running the container mounted to the local filesystem

```
docker run -it --rm --name=sac-mtdynamic \
    --mount type=bind,source=${PWD},target=/home/ubuntu/sac-mtdynamic \
    --mount type=bind,source=/sys/class/powercap/intel-rapl:0,target=/sys/class/powercap/intel-rapl:0 \
    --privileged \
    sac-mtdynamic
```
