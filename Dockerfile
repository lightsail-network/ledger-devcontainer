# You can find more information here: https://github.com/overcat/ledger-devcontainer
FROM ubuntu:focal

# This Dockerfile adds a non-root 'ledgerdev' user with sudo access. However, for Linux,
# this user's GID/UID must match your local user UID/GID to avoid permission issues
# with bind mounts. Update USER_UID / USER_GID if yours is not 1000. See
# https://aka.ms/vscode-remote/containers/non-root-user for details.
ARG USERNAME=ledgerdev
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

ARG LLVM_VERSION=12

ARG NANOS_SDK_VERSION=2.1.0
ARG NANOSP_SDK_VERSION=1.0.3
ARG NANOX_SDK_VERSION=2.0.2-2

ARG ARM_TOOLCHAIN_VERSION=10.3-2021.10
ARG ARM_TOOLCHAIN_AMD64_MD5=2383e4eb4ea23f248d33adc70dc3227e
ARG ARM_TOOLCHAIN_ARM64_MD5=3fe3d8bb693bd0a6e4615b6569443d0d

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -qy && apt-get install -qy \
    apt-utils \
    ca-certificates\
    locales \
    clang-${LLVM_VERSION} \
    clang-tools-${LLVM_VERSION} \
    clang-format-${LLVM_VERSION} \
    lld-${LLVM_VERSION} \
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
    python-is-python3 \
    python3 \
    python3-pip \
    gcc-arm-linux-gnueabihf \
    qemu-user-static \
    gdb-multiarch \
    fish && \
    apt-get autoclean -y && \
    apt-get autoremove -y && \
    apt-get clean && \
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-${LLVM_VERSION} 100 && \
    update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-${LLVM_VERSION} 100

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

# Download Nano S SDK, Nano S Plus SDK and Nano X SDK
RUN cd /opt && git clone --branch ${NANOS_SDK_VERSION} https://github.com/LedgerHQ/nanos-secure-sdk.git nanos-secure-sdk && \
    git clone --branch ${NANOSP_SDK_VERSION} https://github.com/LedgerHQ/nanosplus-secure-sdk.git nanosplus-secure-sdk && \
    git clone --branch ${NANOX_SDK_VERSION} https://github.com/LedgerHQ/nanox-secure-sdk.git nanox-secure-sdk

ENV NANOS_SDK=/opt/nanos-secure-sdk
ENV NANOSP_SDK=/opt/nanoplus-secure-sdk
ENV NANOX_SDK=/opt/nanox-secure-sdk
# Default SDK
ENV BOLOS_SDK=${NANOS_SDK}

RUN cd /opt \
    && git clone https://github.com/LedgerHQ/speculos.git speculos \
    && cd speculos \
    # disable vnc
    && sed -i 's/-DWITH_VNC=1/-DWITH_VNC=0/g' setup.py \
    # disable qt
    && sed -i '/pyqt5/d' setup.py \
    && pip install . \
    # Werkzeug >= 2.1.0 fail
    && pip install Werkzeug==2.0.3 \
    # && pip cache purge
    && rm -rf /root/.cache/pip/

# Set up locale
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Create a non-root user to use if preferred - see https://aka.ms/vscode-remote/containers/non-root-user.
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/fish --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # [Optional] Add sudo support for the non-root user
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=

USER $USERNAME

CMD ["/bin/fish"]