FROM ubuntu:22.04

RUN ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

RUN apt update \
  && apt install -y --no-install-recommends git cmake ninja-build gperf \
  ccache dfu-util device-tree-compiler wget \
  python3-dev python3-pip python3-setuptools python3-tk python3-wheel xz-utils file \
  make gcc libsdl2-dev libmagic1 \
  tzdata \
  && apt clean \
  && rm -rf /var/lib/apt/lists/*

# Install multi-lib gcc (x86 only)
RUN if [ "$(uname -m)" = "x86_64" ]; then \
  apt update \
  && apt install --no-install-recommends -y \
    gcc-multilib \
    g++-multilib \
  && apt clean \
  && rm -rf /var/lib/apt/lists/* \
  ; fi

RUN pip install west pyelftools

ARG ZSDK_VERSION=0.16.6
ENV ZSDK_VERSION=$ZSDK_VERSION

RUN if [ "$(uname -m)" = "x86_64" ]; then \
	wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v$ZSDK_VERSION/zephyr-sdk-${ZSDK_VERSION}_linux-x86_64_minimal.tar.xz \
  && tar -xf zephyr-sdk-${ZSDK_VERSION}_linux-x86_64_minimal.tar.xz -C /opt/ \
  && rm zephyr-sdk-${ZSDK_VERSION}_linux-x86_64_minimal.tar.xz \
  && cd /opt/zephyr-sdk-$ZSDK_VERSION \
  ; fi

RUN if [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ]; then \
	wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v$ZSDK_VERSION/zephyr-sdk-${ZSDK_VERSION}_linux-aarch64_minimal.tar.xz \
  && tar -xf zephyr-sdk-${ZSDK_VERSION}_linux-aarch64_minimal.tar.xz -C /opt/ \
  && rm zephyr-sdk-${ZSDK_VERSION}_linux-aarch64_minimal.tar.xz \
  && cd /opt/zephyr-sdk-$ZSDK_VERSION \
  ; fi

ADD sdk_toolchains /opt/zephyr-sdk-$ZSDK_VERSION/

RUN cd /opt/zephyr-sdk-$ZSDK_VERSION && yes | ./setup.sh

# Create workspace directory
RUN mkdir -p /workspace

RUN cd /workspace && west init -m https://github.com/zephyrproject-rtos/zephyr.git zephyrproject

WORKDIR /workspace/zephyrproject

RUN cd /workspace/zephyrproject && west update
