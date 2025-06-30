FROM sacbase/sac-compiler

RUN apt update \
    && apt install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        numactl \
        cmake \
        curl \
        git \
        stress-ng \
    && apt clean \
    && apt autoclean \
    && apt --purge autoremove

WORKDIR /home/ubuntu

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Check for changes on remote
ADD "https://api.github.com/repos/SacBase/sac-energy/commits?per_page=1" sac-energy.json
# Install SaC energy measuring
RUN git clone --single-branch --recursive https://github.com/SacBase/sac-energy.git \
    && cd sac-energy && mkdir build && cd build \
    && cmake -DTARGETS="seq;mt_pth" .. \
    && make

# Check for changes on remote
ADD "https://api.github.com/repos/JordyAaldering/mtdynamic/commits?per_page=1" mtdynamic.json
# Install dynamic adaptation controller
RUN git clone --single-branch https://github.com/JordyAaldering/mtdynamic.git \
    && cd mtdynamic \
    && LOCAL="/usr/local" make install
