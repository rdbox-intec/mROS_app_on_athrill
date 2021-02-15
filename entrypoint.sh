#!/bin/bash
set -xe

# inside docker script
trap 'kill $(jobs -p)' EXIT

mkdir -p /tmp/ev3rt
mv /root/ev3rt/ev3rt-athrill-ARMv7-A/sdk/mros-obj/memory_mmap.txt /tmp/ev3rt/memory_mmap.txt
mv /root/ev3rt/ev3rt-athrill-ARMv7-A/sdk/mros-obj/device_config_mmap.txt /tmp/ev3rt/device_config_mmap.txt
mv /root/ev3rt/ev3rt-athrill-ARMv7-A/sdk/asp /tmp/ev3rt/asp
mv /root/ev3rt/ev3rt-athrill-ARMv7-A/sdk/mros-obj/unity_mmap.bin /tmp/ev3rt/unity_mmap.bin
mv /root/ev3rt/ev3rt-athrill-ARMv7-A/sdk/mros-obj/athrill_mmap.bin /tmp/ev3rt/athrill_mmap.bin
chmod -R 777 /tmp/ev3rt
chown -R 1000:1000 /tmp/ev3rt

stone "${ROSCORE_ADDRESS}":11311 11311 &

sleep 10

exec "$@"
