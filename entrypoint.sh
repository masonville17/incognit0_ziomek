#!/bin/bash

echo "What in the world is flying past my shoulder? Could it be? It's ziomek version $ZIOMEK_VERSION!"
initial_ipv4=$(ip -4 a show scope global | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
android_internet_ipv4="NA"

USE_VPN=${USE_VPN:-0}
echo "your initial outward ipv4 addres address appears to be $initial_ipv4."

if [[ "${USE_VPN}" -eq 1 ]]; then
    iptables -A OUTPUT -o tun0 -p tcp --dport "$5901" -j DROP
    iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
    echo "VPN is enabled, dont try to connect via $initial_ipv4... You're going to the moon! Attempting VPN connection using your vpn_host.ovpn file."
    openvpn --config "${OVPN_FILE}" --auth-user-pass pass & 
    vpn_pid=$!
    sleep 24
    if ip a show tun0 up > /dev/null 2>&1; then
        vpn_infos=$(ps -f -p $vpn_pid)
        ip_addr=$(curl -s https://ipinfo.io/ip)
        echo "VPN is onnected with split tunnel. Local/VNC ipv4 is: $initial_ipv4, android-internet access is now ipv4:$ip_addr"
    else
        echo "VPN connection (pid:$vpn_pid) failed. were going to exit now. okay?"
        exit 1
    fi
else
    echo "VPN is disabled, it will be just a bit, but you'll be able to connect via initial ip $initial_ipv4"
    android_internet_ipv4=$initial_ipv4
    vpn_pid="NA"

fi

# re/setting up and start VNC service on local address

mkdir -p ~/.vnc
echo "${VNC_PASSWORD:-password}" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd
tightvncserver :1 &
vnc_pid=$!

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

while true; do
    ip_addr=$(curl -s https://ipinfo.io/ip)
    if [[ "${USE_VPN}" -eq 1 ]]; then
        if ! ip a show tun0 up > /dev/null 2>&1; then
            echo "VPN INFOS: connection (pid:$vpn_pid) has stopped becoming viable. were going to exit now. okay?"
            exit 1
        else
            vpn_infos=$(ps -f -p $vpn_pid)
            echo "VPN INFOS: connected with split tunnel. Local/VNC ipv4 is: $initial_ipv4, android-internet access is now ipv4:$ip_addr"
        fi
    fi
    echo "VNC server is running on $initial_ipv4:5901, android emulator is running on $initial_ipv4:5901, android-internet access is now ipv4:$ip_addr"
    echo "Sleeping for 10 and then check again..."
    sleep 600
done
trap "kill $vpn_pid" EXIT


