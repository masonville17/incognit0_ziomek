#!/bin/bash

mkdir -p ~/.vnc
echo "${VNC_PASSWORD:-password}" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd
tightvncserver :1

echo "Launching emulator with:"
echo "AVD_DEVICE=${AVD_DEVICE}"
echo "GPU_TARGET=${GPU_TARGET}"
echo "RESOLUTION=${EMULATOR_RESOLUTION}"
echo "DENSITY=${EMULATOR_DENSITY}"
echo "CPU_CORES=${CPU_CORES}"
echo "RAM_SIZE=${RAM_SIZE}"
echo "DISK_SIZE=${DISK_SIZE}"
echo "ENABLE_AUDIO=${ENABLE_AUDIO}"
echo "NETWORK_SPEED=${NETWORK_SPEED}"
DISPLAY=:1 cd $ANDROID_HOME/cmdline-tools/latest/bin && /opt/android-sdk/emulator/emulator \
    -avd "${AVD_DEVICE}" \
    -gpu "${GPU_TARGET}" \
    -skin "${EMULATOR_RESOLUTION}" \
    -density "${EMULATOR_DENSITY}" \
    -cores "${CPU_CORES}" \
    -memory "${RAM_SIZE}" \
    -partition-size "${DISK_SIZE}" \
    -no-snapshot \
    -${ENABLE_AUDIO:+audio} \
    -network-speed "${NETWORK_SPEED}" \
    -no-window -verbose &

# Keep the container running
tail -f /dev/null    