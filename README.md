## Building the container and removing outdated dangling versions

```
docker build --no-cache -t sac .
docker image prune
```

## Running the container mounted to the local filesystem

```
docker run -it --rm --name=sac \
    --mount type=bind,source=${PWD},target=/home/ubuntu/sac \
    --mount type=bind,source=/sys/class/powercap/intel-rapl:0,target=/sys/class/powercap/intel-rapl:0 \
    --privileged \
    sac
```
