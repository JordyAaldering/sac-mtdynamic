FROM ubuntu:25.04

RUN apt update \
    && apt install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        numactl \
        cmake \
        curl \
        git \
    && apt clean \
    && apt autoclean \
    && apt --purge autoremove

WORKDIR /home/ubuntu

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install SaC compiler
RUN curl -OL https://gitlab.sac-home.org/sac-group/sac-packages/-/raw/master/latest/weekly/Ubl22/sac2c-basic.deb \
    && apt install -y ./sac2c-basic.deb \
    && rm sac2c-basic.deb

# Install SaC standard library
RUN curl -OL https://gitlab.sac-home.org/sac-group/sac-packages/-/raw/master/latest/weekly/Ubl22/stdlib-basic.deb \
    && apt install -y ./stdlib-basic.deb \
    && rm stdlib-basic.deb

# Install SaC energy measuring
RUN git clone --single-branch --recursive https://github.com/SacBase/sac-energy.git \
    && cd sac-energy \
    && make

# Install dynamic adaptation controller
RUN git clone --single-branch https://github.com/JordyAaldering/mtdynamic.git \
    && cd mtdynamic \
    && make

HEALTHCHECK CMD sac2c -V
