FROM ubuntu:xenial-20200916 as ev3rt-builder

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
        git \
        build-essential \
        gcc-arm-none-eabi

WORKDIR /root
RUN git clone --depth 1 https://github.com/toppers/athrill.git && \
    git clone --depth 1 https://github.com/toppers/athrill-target-ARMv7-A.git && \
    git clone --depth 1 https://github.com/toppers/asp-athrill-mbed.git && \
    git clone --depth 1 https://github.com/tlk-emb/mROS.git && \
    sed -i '1i#include "kernel_cfg.h"' mROS/mros-lib/mros-src/api/ros.cpp

COPY ./mROS_app /root/ev3rt-athrill-ARMv7-A
RUN mkdir -p /root/ev3rt-athrill-ARMv7-A/cfg/cfg

WORKDIR /root/ev3rt-athrill-ARMv7-A
RUN mkdir -p cfg/cfg && \
    cp cfg/cfg-linux-64 cfg/cfg/cfg && \
    chmod +x cfg/cfg/cfg
WORKDIR /root/ev3rt-athrill-ARMv7-A/sdk/mros-obj
RUN sed -i -e "s/^#define MROS_MASTER_IPADDR\t*\"192.168.11.49\"/#define MROS_MASTER_IPADDR\t\t\t\t\t\t\"127.0.0.1\"/g" mros_config/mros_sys_config.h
RUN sed -i -e "s/^#define MROS_NODE_IPADDR\t*\"192.168.11.49\"/#define MROS_NODE_IPADDR\t\t\t\t\t\t\"127.0.0.1\"/g" mros_config/mros_sys_config.h
RUN make clean; make ATHRILL_BUILD_TARGET=ubuntu18

# MultiStage Build
FROM rdbox/athrill:v1.1.1
RUN apt-get update && apt-get install -y --no-install-recommends \
        stone && \
    rm -rf /var/lib/apt/lists/*
COPY --from=ev3rt-builder /root/ev3rt-athrill-ARMv7-A/sdk/mros-obj/memory_mmap.txt /root/ev3rt/ev3rt-athrill-ARMv7-A/sdk/mros-obj/memory_mmap.txt
COPY --from=ev3rt-builder /root/ev3rt-athrill-ARMv7-A/sdk/mros-obj/device_config_mmap.txt /root/ev3rt/ev3rt-athrill-ARMv7-A/sdk/mros-obj/device_config_mmap.txt
COPY --from=ev3rt-builder /root/ev3rt-athrill-ARMv7-A/sdk/asp /root/ev3rt/ev3rt-athrill-ARMv7-A/sdk/asp
COPY --from=ev3rt-builder /root/ev3rt-athrill-ARMv7-A/sdk/mros-obj/unity_mmap.bin /root/ev3rt/ev3rt-athrill-ARMv7-A/sdk/mros-obj/unity_mmap.bin
COPY --from=ev3rt-builder /root/ev3rt-athrill-ARMv7-A/sdk/mros-obj/athrill_mmap.bin /root/ev3rt/ev3rt-athrill-ARMv7-A/sdk/mros-obj/athrill_mmap.bin
COPY ./entrypoint.sh /entrypoint.sh

RUN sed -i -e '$d' /root/ev3rt/ev3rt-athrill-ARMv7-A/sdk/mros-obj/memory_mmap.txt && \
    sed -i -e '$d' /root/ev3rt/ev3rt-athrill-ARMv7-A/sdk/mros-obj/memory_mmap.txt && \
    echo "MMAP, 0x40000000, /tmp/ev3rt/athrill_mmap.bin" >> /root/ev3rt/ev3rt-athrill-ARMv7-A/sdk/mros-obj/memory_mmap.txt && \
    echo "MMAP, 0x40010000, /tmp/ev3rt/unity_mmap.bin" >> /root/ev3rt/ev3rt-athrill-ARMv7-A/sdk/mros-obj/memory_mmap.txt

ENTRYPOINT ["/entrypoint.sh"]
CMD ["athrill2", "-c1", "-t", "-1", "-m", "/tmp/ev3rt/memory_mmap.txt", "-d", "/tmp/ev3rt/device_config_mmap.txt", "/tmp/ev3rt/asp"]
