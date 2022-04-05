# You can find more information here: https://github.com/overcat/ledger-devcontainer
FROM ubuntu:focal

# use apt mirror instead of default archives if specified
# to use, specify the build arg or as an env var on the host machine
# e.g.:
#   http://mirrors.tuna.tsinghua.edu.cn/
#   http://<country-code>.archive.ubuntu.com/
#   http://<aws-region>.ec2.archive.ubuntu.com
ARG APT_MIRROR=

# PyPi Mirror Config
# e.g.:
#   PIP_INDEX=https://mirrors.aliyun.com/pypi
#   PIP_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/
ARG PIP_INDEX=
ARG PIP_INDEX_URL=

# This Dockerfile adds a non-root 'vscode' user with sudo access. However, for Linux,
# this user's GID/UID must match your local user UID/GID to avoid permission issues
# with bind mounts. Update USER_UID / USER_GID if yours is not 1000. See
# https://aka.ms/vscode-remote/containers/non-root-user for details.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ARG LLVM_VERSION=12

ARG NANOS_SDK_VERSION=2.1.0
ARG NANOSPLUS_SDK_VERSION=1.0.2
ARG NANOX_SDK_VERSION=2.0.2-2

ARG ARM_TOOLCHAIN_VERSION=10.3-2021.10
ARG ARM_TOOLCHAIN_AMD64_MD5=2383e4eb4ea23f248d33adc70dc3227e
ARG ARM_TOOLCHAIN_ARM64_MD5=3fe3d8bb693bd0a6e4615b6569443d0d

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

RUN if [ ! -z "${APT_MIRROR}" ]; then \
    sed -i \
    -e "s|http://ports.ubuntu.com/|${APT_MIRROR}|" \
    /etc/apt/sources.list \
    ; fi \
    ; grep "^[^#;]" /etc/apt/sources.list


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

# Download Nano S SDK, Nano S Plus SDK and Nano X SDK
RUN cd /opt && git clone --branch ${NANOS_SDK_VERSION} https://github.com/LedgerHQ/nanos-secure-sdk.git nanos-secure-sdk && \
    git clone --branch ${NANOSPLUS_SDK_VERSION} https://github.com/LedgerHQ/nanosplus-secure-sdk.git nanosplus-secure-sdk && \
    git clone --branch ${NANOX_SDK_VERSION} https://github.com/LedgerHQ/nanox-secure-sdk.git nanox-secure-sdk

# Set PyPi Mirror (root)
RUN if [ ! -z "${PIP_INDEX}" ] && [ ! -z "${PIP_INDEX_URL}" ]; then \
    pip3 config set global.index ${PIP_INDEX} && pip3 config set global.index-url ${PIP_INDEX_URL} \
    ; fi

RUN cd /opt \
    && git clone https://github.com/LedgerHQ/speculos.git speculos \
    && cd speculos \
    # disable vnc
    && sed -i 's/-DWITH_VNC=1/-DWITH_VNC=0/g' setup.py \
    # disable qt
    && sed -i '/pyqt5/d' setup.py \
    && pip3 install --no-cache-dir . \
    # https://github.com/pypa/pip/issues/4880
    && python3 setup.py install \
    # Werkzeug >= 2.1.0 fail
    && pip3 install --no-cache-dir Werkzeug==2.0.3

# Set up locale
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Create a non-root user to use if preferred - see https://aka.ms/vscode-remote/containers/non-root-user.
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # [Optional] Add sudo support for the non-root user
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER ${USERNAME}
# Set PyPi Mirror (vscode)
RUN if [ ! -z "${PIP_INDEX}" ] && [ ! -z "${PIP_INDEX_URL}" ]; then \
    pip3 config set global.index ${PIP_INDEX} && pip3 config set global.index-url ${PIP_INDEX_URL} \
    ; fi

# Adding GCC and speculos to path
ENV PATH=/opt/gcc-arm-none-eabi-${ARM_TOOLCHAIN_VERSION}/bin:/opt/speculos:$PATH

ENV NANOS_SDK=/opt/nanos-secure-sdk
ENV NANOSPLUS_SDK=/opt/nanoplus-secure-sdk
ENV NANOX_SDK=/opt/nanox-secure-sdk

# Default SDK
ENV BOLOS_SDK=${NANOS_SDK}

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=

CMD ["/usr/bin/env", "fish"]