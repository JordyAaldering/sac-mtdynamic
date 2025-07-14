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

## Running the benchmarks

Replace `<threads>` by the maximum number of threads, e.g. `4`.

Replace `<taskset>` by a comma-separated list of the identifiers of the physical/performance cores, e.g. `0,2,4,6`.

Replace `<powercap>` by the maximum power limit in uW, e.q. `125000000`.

```
./scripts/bench.sh results/rust_flash.csv rust/target/debug/flash 2048 <threads> <taskset> <powercap>
./scripts/bench.sh results/rust_flash.csv rust/target/debug/flash 4096 <threads> <taskset> <powercap>

./scripts/bench.sh results/rust_matmul_naive.csv rust/target/debug/matmul-naive 500 <threads> <taskset> <powercap>
./scripts/bench.sh results/rust_matmul_naive.csv rust/target/debug/matmul-naive 1500 <threads> <taskset> <powercap>

./scripts/bench.sh results/rust_matmul_transp.csv rust/target/debug/matmul-transp 500 <threads> <taskset> <powercap>
./scripts/bench.sh results/rust_matmul_transp.csv rust/target/debug/matmul-transp 1500 <threads> <taskset> <powercap>

./scripts/bench.sh results/rust_nbody rust/target/debug/nbody 5000 <threads> <taskset> <powercap>
./scripts/bench.sh results/rust_nbody rust/target/debug/nbody 15000 <threads> <taskset> <powercap>

./scripts/bench.sh results/rust_stencil rust/target/debug/stencil 5000 <threads> <taskset> <powercap>
./scripts/bench.sh results/rust_stencil rust/target/debug/stencil 15000 <threads> <taskset> <powercap>
```

And the same for SaC

```
./scripts/bench.sh results/sac_flash.csv bin/flash_mt 2048 <threads> <taskset> <powercap>
./scripts/bench.sh results/sac_flash.csv bin/flash_mt 4096 <threads> <taskset> <powercap>

./scripts/bench.sh results/sac_matmul_naive.csv bin/matmul_naive_mt 500 <threads> <taskset> <powercap>
./scripts/bench.sh results/sac_matmul_naive.csv bin/matmul_naive_mt 1500 <threads> <taskset> <powercap>

./scripts/bench.sh results/sac_matmul_transp.csv bin/matmul_transp_mt 500 <threads> <taskset> <powercap>
./scripts/bench.sh results/sac_matmul_transp.csv bin/matmul_transp_mt 1500 <threads> <taskset> <powercap>

./scripts/bench.sh results/sac_nbody bin/nbody_mt 5000 <threads> <taskset> <powercap>
./scripts/bench.sh results/sac_nbody bin/nbody_mt 15000 <threads> <taskset> <powercap>

./scripts/bench.sh results/sac_stencil bin/stencil_mt 5000 <threads> <taskset> <powercap>
./scripts/bench.sh results/sac_stencil bin/stencil_mt 15000 <threads> <taskset> <powercap>
```
