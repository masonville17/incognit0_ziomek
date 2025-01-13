FROM ubuntu:24.04
LABEL maintainer="Mason Stelter"
ENV ZIOMEK_VERSION="0.1.1"
ENV DEBIAN_FRONTEND=noninteractive
ARG GPU_TARGET=none
ENV GPU_TARGET=${GPU_TARGET}
ARG EMULATOR_RESOLUTION=1080x1920
ENV EMULATOR_RESOLUTION=${EMULATOR_RESOLUTION}
ARG EMULATOR_DENSITY=420
ENV EMULATOR_DENSITY=${EMULATOR_DENSITY}
ARG AVD_DEVICE="$AVD_DEVICE"
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
ENV VNC_PASSWORD=password

# VNC and Timezone.
ENV VNC_PASSWORD=${VNC_PASSWORD}
ARG TZ="$AVD_DEVICE"
ENV TZ=${AVD_DEVICE}
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH


# Install dependencies
# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive \
        apt-get update && apt-get install -y \
            adb \
            qemu-kvm \
            libvirt-daemon-system \
            libvirt-clients \
            unzip \
            wget \
            bash \
            xvfb \
            tightvncserver \
            openjdk-11-jdk \
            openjdk-17-jdk \
            wget \ 
            wget \
            unzip \
            openvpn \
            qemu-kvm \
            libvirt-daemon-system \
            libvirt-clients \
            tightvncserver \
            unzip && \
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone
# Install Android SDK components
# Install Android SDK
RUN mkdir -p /opt/android-sdk/cmdline-tools/latest && \
    cd /opt/android-sdk && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip && \
    unzip commandlinetools-linux-10406996_latest.zip -d /opt/android-sdk/cmdline-tools/latest && \
    mv /opt/android-sdk/cmdline-tools/latest/cmdline-tools/* /opt/android-sdk/cmdline-tools/latest/ && \
    rm -rf /opt/android-sdk/cmdline-tools/latest/cmdline-tools && \
    rm commandlinetools-linux-10406996_latest.zip && \
    chmod +x /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager && \
    echo "AVD_DEVICE: ${AVD_DEVICE}" && \
    API_LEVEL=${AVD_DEVICE#*_API_} && \
    echo "Parsed API_LEVEL: $API_LEVEL" && \
    mkdir -p /home/runner/.android && touch /home/runner/.android/repositories.cfg && \
    cd $ANDROID_HOME/cmdline-tools/latest/bin && \
yes | ./sdkmanager --sdk_root=$ANDROID_HOME --licenses && \
./sdkmanager --sdk_root=${ANDROID_HOME} --verbose --channel=0 "system-images;android-30;google_apis_playstore;x86" && \
./sdkmanager --sdk_root=${ANDROID_HOME} --verbose --channel=0 "build-tools;31.0.0" && \
./sdkmanager --sdk_root=${ANDROID_HOME} --verbose --channel=0 "platform-tools" && \
./sdkmanager --sdk_root=${ANDROID_HOME} --verbose --channel=0 "emulator"
# set up VNC
RUN mkdir ~/.vnc && echo "$VNC_PASSWORD" | vncpasswd -f > ~/.vnc/passwd && chmod 600 ~/.vnc/passwd

# Entrypoint script
WORKDIR ${ANDROID_HOME}/cmdline-tools/latest/bin
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/bin/bash", "/usr/local/bin/entrypoint.sh"]
