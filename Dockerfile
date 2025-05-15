FROM ubuntu:25.04

RUN apt update \
    && apt install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        numactl \
        cmake \
        curl \
        git \
        # Additional SaC dependencies
        xsltproc \
        python3 \
        bison \
        flex \
        m4 \
    && apt clean \
    && apt autoclean \
    && apt --purge autoremove

WORKDIR /home/ubuntu

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install SaC compiler
RUN git clone --recursive --single-branch https://gitlab.sac-home.org/sac-group/sac2c.git \
    && cd sac2c && mkdir build && cd build \
    && cmake -DCMAKE_BUILD_TYPE=RELEASE .. \
    && make -j4 \
    && cp sac2c_p /usr/local/bin/sac2c \
    && sac2c -V

# Install SaC standard library
RUN git clone --recursive --single-branch https://github.com/SacBase/Stdlib.git \
    && cd Stdlib && mkdir build && cd build \
    && cmake -DBUILD_EXT=OFF -DFULLTYPES=OFF -DTARGETS="seq;mt_pth" .. \
    && make -j4

# Install SaC energy measuring
RUN git clone --single-branch --recursive https://github.com/SacBase/sac-energy.git \
    && cd sac-energy \
    && make

# Install dynamic adaptation controller
RUN git clone --single-branch https://github.com/JordyAaldering/mtdynamic.git \
    && cd mtdynamic \
    && make

HEALTHCHECK CMD sac2c -V
