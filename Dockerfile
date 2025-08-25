# You can find more information here: https://github.com/overcat/ledger-devcontainer
FROM ubuntu:24.04

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -qy && apt-get install -qy \
    apt-utils \
    ca-certificates\
    locales \
    clang \
    clang-tools \
    clang-format \
    llvm \
    lld \
    cmake \
    curl \
    doxygen \
    git \
    lcov \
    libbsd-dev \
    libcmocka0 \
    libcmocka-dev \
    make \
    protobuf-compiler \
    libxcb-cursor0 \
    python3 \
    python3-pip \
    python3-pyqt5 \
    nodejs \
    npm \
    fish \
    gcc-arm-linux-gnueabihf \
    qemu-user-static \
    gdb-multiarch && \
    apt-get autoclean -y && \
    apt-get autoremove -y && \
    apt-get clean

ARG ARM_TOOLCHAIN_VERSION=10.3-2021.10
ARG ARM_TOOLCHAIN_AMD64_MD5=2383e4eb4ea23f248d33adc70dc3227e
ARG ARM_TOOLCHAIN_ARM64_MD5=3fe3d8bb693bd0a6e4615b6569443d0d

# ARM Embedded Toolchain
# Integrity is checked using the MD5 checksum provided by ARM at https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads
RUN case $(uname -m) in \
    x86_64 | amd64) \
    ARCH=x86_64 \
    MD5=${ARM_TOOLCHAIN_AMD64_MD5};; \
    aarch64 | arm64) \
    ARCH=aarch64; \
    MD5=${ARM_TOOLCHAIN_ARM64_MD5};; \
    *) echo "Unknown architecture" && exit 1;; \
    esac && \
    curl -sSfL -o arm-toolchain.tar.bz2 "https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-rm/${ARM_TOOLCHAIN_VERSION}/gcc-arm-none-eabi-${ARM_TOOLCHAIN_VERSION}-${ARCH}-linux.tar.bz2" && \
    echo ${MD5} arm-toolchain.tar.bz2 > /tmp/arm-toolchain.md5 && \
    md5sum --check /tmp/arm-toolchain.md5 && rm /tmp/arm-toolchain.md5 && \
    tar xf arm-toolchain.tar.bz2 -C /opt && \
    rm arm-toolchain.tar.bz2

# Adding ARM Embedded Toolchain to path
ENV PATH=/opt/gcc-arm-none-eabi-${ARM_TOOLCHAIN_VERSION}/bin:$PATH

ARG GIT_SERVER=https://github.com/LedgerHQ

# Unified SDK
ENV LEDGER_SECURE_SDK=/opt/ledger-secure-sdk
RUN git clone "$GIT_SERVER/ledger-secure-sdk.git" "$LEDGER_SECURE_SDK"

# Latest Nano S SDK (OS nanos_2.1.0 => based on API_LEVEL LNS)
ENV NANOS_SDK=/opt/nanos-secure-sdk
RUN git -C "$LEDGER_SECURE_SDK" worktree add "$NANOS_SDK" lns-2.1.0-v24.0
RUN echo nanos > $NANOS_SDK/.target

# Latest Nano X SDK based on API_LEVEL 24
ENV NANOX_SDK=/opt/nanox-secure-sdk
RUN git -C "$LEDGER_SECURE_SDK" worktree add "$NANOX_SDK" v24.1.0
RUN echo nanox > $NANOX_SDK/.target

# Latest Nano S+ SDK based on API_LEVEL 24
ENV NANOSP_SDK=/opt/nanosplus-secure-sdk
RUN git -C "$LEDGER_SECURE_SDK" worktree add "$NANOSP_SDK" v24.1.0
RUN echo nanos2 > $NANOSP_SDK/.target

# Latest Stax SDK based on API_LEVEL 24
ENV STAX_SDK=/opt/stax-secure-sdk
RUN git -C "$LEDGER_SECURE_SDK" worktree add "$STAX_SDK" v24.1.0
RUN echo stax > $STAX_SDK/.target

# Latest Flex SDK based on API_LEVEL 24
ENV FLEX_SDK=/opt/flex-secure-sdk
RUN git -C "$LEDGER_SECURE_SDK" worktree add "$FLEX_SDK" v24.1.0
RUN echo flex > $FLEX_SDK/.target

# Latest Apex P SDK based on API_LEVEL 25
ENV APEX_P_SDK=/opt/apex-secure-sdk
RUN git -C "$LEDGER_SECURE_SDK" worktree add "$APEX_P_SDK" v25.1.0
RUN echo apex_p > $APEX_P_SDK/.target

# Default SDK
ENV BOLOS_SDK=$NANOS_SDK

# https://pypi.org/project/ledgerblue/
# https://pypi.org/project/ledgerwallet/
# https://pypi.org/project/speculos/
RUN pip3 install --no-cache-dir --break-system-packages ledgerwallet==0.6.0 speculos==0.25.3

# Rust
ARG RUST_VERSION=nightly-2024-12-01
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain "$RUST_VERSION" -y
ENV PATH=$PATH:/root/.cargo/bin
RUN rustup component add rust-src --toolchain "$RUST_VERSION"
# https://crates.io/crates/cargo-ledger
RUN cargo install --locked --version 1.9.0 cargo-ledger && cargo ledger setup

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=

CMD ["/bin/bash"]