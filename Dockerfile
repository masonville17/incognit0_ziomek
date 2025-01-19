FROM ubuntu:24.04
LABEL maintainer="Mason Stelter"
ENV ZIOMEK_VERSION="0.1.1"
ENV DEBIAN_FRONTEND=noninteractive

ENV USER=root
ENV HOME=/root
ARG AVD_DEVICE="Pixel_4_API_30_google_apis_playstore_x86_64"
ENV AVD_DEVICE=${AVD_DEVICE}
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH
ENV ANDROID_AVD_HOME=/root/.android/avd
ENV ANDROID_SDK_HOME=/root
ENV ANDROID_SDK_ROOT=/opt/android-sdk


ARG GPU_TARGET=none
ENV GPU_TARGET=${GPU_TARGET}
ARG EMULATOR_RESOLUTION=1080x1920
ENV EMULATOR_RESOLUTION=${EMULATOR_RESOLUTION}
ARG EMULATOR_DENSITY=420
ENV EMULATOR_DENSITY=${EMULATOR_DENSITY}

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
ENV VNC_PASSWORD=password

# VNC and Timezone.
ENV VNC_PASSWORD=${VNC_PASSWORD}

ARG ANDROID_SYS_LOCALE="en_IN"
ENV ANDROID_SYS_LOCALE=${ANDROID_SYS_LOCALE}
ARG ANDROID_TIMEZONE="Asia/Kolkata"
ENV ANDROID_TIMEZONE=${ANDROID_TIMEZONE}
ARG ANDROID_COUNTRY="IN"
ENV ANDROID_COUNTRY=${ANDROID_COUNTRY}
ENV TZ=${ANDROID_TIMEZONE}

# Install Android SDK components

# Install dependencies
# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive \
        apt-get update && apt-get install -y \
            adb \
            qemu-kvm \
            libvirt-daemon-system \
            libvirt-clients \
            unzip \
            xauth \
            wget \
            curl \
            bash \
            wmctrl \
            xvfb \
            sudo \
            procps \
            tightvncserver \
            openjdk-11-jdk \
            openjdk-17-jdk \
            wget \ 
            xfonts-75dpi xfonts-100dpi xfonts-base \
            x11-xserver-utils \
            dnsutils \
            ca-certificates \
            iptables \
            wget \
            unzip \
            openvpn \
            qemu-kvm \
            xterm xorg i3 x11-apps dbus dbus-x11 \
            libvirt-daemon-system \
            libvirt-clients \
            tightvncserver \
            unzip && \
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    mkdir -p /var/run/dbus && \
    echo $TZ > /etc/timezone
RUN rm -rf /root/.vnc/xstartup && mkdir -p /root/.vnc && \
    cat <<EOF > /root/.vnc/xstartup
#!/bin/bash
xrdb \$HOME/.Xresources
i3 &
EOF
RUN chmod +x /root/.vnc/xstartup
# Install SDK and tools
RUN mkdir -p /root/.android && touch /root/.android/repositories.cfg && \
    mkdir -p /opt/android-sdk/cmdline-tools/latest && \
    cd /opt/android-sdk && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip && \
    unzip commandlinetools-linux-10406996_latest.zip -d /opt/android-sdk/cmdline-tools/latest && \
    mv /opt/android-sdk/cmdline-tools/latest/cmdline-tools/* /opt/android-sdk/cmdline-tools/latest/ && \
    rm -rf /opt/android-sdk/cmdline-tools/latest/cmdline-tools && \
    rm commandlinetools-linux-10406996_latest.zip && \
    chmod +x /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager && \
    yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses && \
    $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_HOME} \
        "system-images;android-30;google_apis_playstore;x86" \
        "build-tools;31.0.0" \
        "platform-tools" \
        "emulator" && \
        $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_HOME} "platforms;android-30" && \
        chown -R root:root /opt/android-sdk && chmod -R 755 /opt/android-sdk && \
        touch /root/.Xauthority && \
        chmod 600 /root/.Xauthority        

EXPOSE 5901 5900 5800 5899


# set up VNC
WORKDIR "$ANDROID_HOME/cmdline-tools/latest/bin"
COPY entrypoint.sh .
RUN chmod +x "entrypoint.sh" && \
        rm -rf /run/dbus/dbus.pid /run/dbus/pid
ENTRYPOINT ["/bin/bash", "entrypoint.sh"]
