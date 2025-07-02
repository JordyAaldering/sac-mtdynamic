#!/bin/bash

./scripts_sel265k/power_sac_flash.sh
./scripts_sel265k/power_sac_matmul_naive.sh
./scripts_sel265k/power_sac_matmul_transp.sh
./scripts_sel265k/power_sac_nbody.sh
./scripts_sel265k/power_sac_stencil.sh

./scripts_sel265k/power_rust_flash.sh
./scripts_sel265k/power_rust_matmul_naive.sh
./scripts_sel265k/power_rust_matmul_transp.sh
./scripts_sel265k/power_rust_nbody.sh
./scripts_sel265k/power_rust_stencil.sh
