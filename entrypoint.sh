#!/bin/bash

echo "What in the world is flying past my shoulder? Could it be? It's ziomek version $ZIOMEK_VERSION!"
initial_ipv4=$(ip -4 a show scope global | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
USE_VPN=${USE_VPN:-0}
echo "your initial outward ipv4 addres address appears to be $initial_ipv4."

if [[ "${USE_VPN}" -eq 1 ]]; then
    iptables -A OUTPUT -o tun0 -p tcp --dport "$5901" -j DROP
    iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
    echo "VPN is enabled, dont try to connect via $initial_ipv4... You're going to the moon! Attempting VPN connection using your vpn_host.ovpn file."
    openvpn --config "${OVPN_FILE}" --auth-user-pass pass & 
    vpn_pid=$!
else
    echo "VPN is disabled, it will be just a bit, but you'll be able to connect via initial ip $initial_ipv4"
fi

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

echo "connect with: vncviewer ipv4:1"
tail -f /dev/null    