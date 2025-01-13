FROM ubuntu:20.04
ARG GPU_TARGET=none
ENV GPU_TARGET=${GPU_TARGET}
ARG EMULATOR_RESOLUTION=1080x1920
ENV EMULATOR_RESOLUTION=${EMULATOR_RESOLUTION}
ARG EMULATOR_DENSITY=420
ENV EMULATOR_DENSITY=${EMULATOR_DENSITY}
ARG AVD_DEVICE=Pixel_4_API_30
ENV AVD_DEVICE=${AVD_DEVICE}
ARG CPU_CORES=2
ENV CPU_CORES=${CPU_CORES}
ARG RAM_SIZE=2048M
ENV RAM_SIZE=${RAM_SIZE}
ARG DISK_SIZE=16G
ENV DISK_SIZE=${DISK_SIZE}
ARG ENABLE_AUDIO=true
ENV ENABLE_AUDIO=${ENABLE_AUDIO}
ARG ENABLE_HARDWARE_KEYBOARD=true
ENV ENABLE_HARDWARE_KEYBOARD=${ENABLE_HARDWARE_KEYBOARD}
ARG NETWORK_SPEED=full
ENV NETWORK_SPEED=${NETWORK_SPEED}

# Install dependencies
RUN apt-get update && apt-get install -y \
    openvpn adb qemu-kvm libvirt-daemon-system libvirt-clients unzip wget openjdk-11-jdk xvfb tightvncserver \
    && rm -rf /var/lib/apt/lists/*

# Install Android SDK
RUN mkdir /opt/android-sdk && cd /opt/android-sdk && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip && \
    unzip commandlinetools-linux-8512546_latest.zip -d /opt/android-sdk && \
    rm commandlinetools-linux-8512546_latest.zip && \
    yes | /opt/android-sdk/cmdline-tools/bin/sdkmanager --install "platform-tools" "emulator" "system-images;android-30;google_apis;x86_64" && \
    /opt/android-sdk/cmdline-tools/bin/sdkmanager --licenses

# Create an AVD
RUN echo "no" | /opt/android-sdk/emulator/emulator --avd Pixel_4_API_30 --gpu swiftshader_indirect

# Set up VNC for GUI
RUN mkdir ~/.vnc && echo "password" | vncpasswd -f > ~/.vnc/passwd && chmod 600 ~/.vnc/passwd

# Entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/opt/android-sdk/emulator/emulator", \
            "-avd", "${AVD_DEVICE}", \
            "-gpu", "${GPU_TARGET}", \
            "-skin", "${EMULATOR_RESOLUTION}", \
            "-density", "${EMULATOR_DENSITY}", \
            "-cores", "${CPU_CORES}", \
            "-memory", "${RAM_SIZE}", \
            "-partition-size", "${DISK_SIZE}", \
            "-no-snapshot", \
            "-audio", "${ENABLE_AUDIO}", \
            "-network-speed", "${NETWORK_SPEED}"]