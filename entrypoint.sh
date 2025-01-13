#!/bin/bash
set -e
echo "Checking SDK installation..."
echo "ANDROID_HOME: $ANDROID_HOME"
echo "ANDROID_SDK_ROOT: $ANDROID_SDK_ROOT"
set -e

if [ ! -f "/root/.Xauthority" ]; then
    touch /root/.Xauthority
    echo "Created missing /root/.Xauthority"
fi

echo "What in the world is flying past my shoulder? Could it be? It's ziomek version $ZIOMEK_VERSION!"
initial_ipv4=$(ip -4 a show scope global | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
android_internet_ipv4="NA"

USE_VPN=${USE_VPN:-0}
echo "your initial outward ipv4 addres address appears to be $initial_ipv4."

if [[ "${USE_VPN}" -eq 1 ]]; then
    iptables -A OUTPUT -o tun0 -p tcp --dport "$5901" -j DROP
    iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
    OVPN_FILE=$(find /vpn -name "*.ovpn" | shuf -n 1)
    chmod 600 /vpn/passfile
    echo "VPN is enabled, dont try to connect via $initial_ipv4... You're going to the moon! Attempting VPN connection with $OVPN_FILE."
    cd /vpn && openvpn --config "${OVPN_FILE}" --auth-user-pass /vpn/passfile & 
    vpn_pid=$!
    sleep 24
    if ip a show tun0 up > /dev/null 2>&1; then
        vpn_infos=$(ps -f -p $vpn_pid)
        ip_addr=$(curl -s https://ipinfo.io/ip)
        echo "VPN is onnected with split tunnel. Local/VNC ipv4 is: $initial_ipv4, android-internet access is now ipv4:$ip_addr via $OVPN_FILE; $vpn_infos"
    else
        vpn_infos="VPN connection (pid:$vpn_pid) failed."
        ip_addr=$initial_ipv4
        echo "$vpn_infos. were going to exit now. okay?"
        exit 1
    fi
else
    echo "VPN is disabled, it will be just a bit, but you'll be able to connect via initial ip $initial_ipv4"
    android_internet_ipv4=$initial_ipv4
    ip_addr
    vpn_infos="Sorry sir or madam, no VPN here!"
    ip_addr=$initial_ipv4
fi

# re/setting up and start VNC service on local address

mkdir -p ~/.vnc
echo "${VNC_PASSWORD:-password}" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd
export DISPLAY=:1
tightvncserver :1 &
vnc_pid=$!

echo "Checking AVD directory at $ANDROID_AVD_HOME:"

if [ ! -f "$ANDROID_AVD_HOME/${AVD_DEVICE}.ini" ]; then \
    echo "AVD ${AVD_DEVICE} not found. Creating AVD..."; \
    /opt/android-sdk/cmdline-tools/latest/bin/avdmanager create avd \
        --name "${AVD_DEVICE}" \
        --package "system-images;android-30;google_apis_playstore;x86" \
        --device "pixel_4" \
        --force; \
fi

DISPLAY=:1 $ANDROID_HOME/emulator/emulator \
    -avd "${AVD_DEVICE}" \
    -${GPU_TARGET:+gpu "${GPU_TARGET}"} \
    -skin "${EMULATOR_RESOLUTION}" \
    -cores "${CPU_CORES}" \
    -memory "${RAM_SIZE}" \
    -partition-size "${DISK_SIZE}" \
    -no-snapshot \
    -${ENABLE_AUDIO:+audio none} \
    -network-speed "${NETWORK_SPEED}" \
    -no-window -verbose &
emulator_pid=$!

while true; do
    ip_addr=$(curl -s https://ipinfo.io/ip)
    if [[ "${USE_VPN}" -eq 1 ]]; then
        if ! ip a show tun0 up > /dev/null 2>&1; then
            echo "VPN INFOS: connection (pid:$vpn_pid) via $OVPN_FILE has stopped becoming viable. were going to exit now. okay? $(ps -f -p $vpn_pid)"
            exit 1
        else
            echo "VPN INFOS: $(ps -f -p $vpn_pid) pid:$vpn_pid using $OVPN_FILE"
        fi
    else
        echo "VPN INFOS: Sorry sir or madam, no VPN here!"
    fi
    # killswitch, vpn, emulator infos
    echo "NETWORK INFOS: local/vnc ip: $initial_ipv4, android-internet ip:$ip_addr"
    echo "VNC INFOS: $(ps -f -p $vnc_pid) pid:$vnc_pid"
    echo "ANDROID INFOS: $(ps -f -p $emulator_pid) pid:$emulator_pid"
    echo "KILLSWITCH INFOS: Sleeping for 10 and then check again..."
    sleep 600
done
trap "kill $vpn_pid" EXIT


