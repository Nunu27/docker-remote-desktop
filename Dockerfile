# syntax=docker/dockerfile:1

# ----------------------------------------------------------------------------
# Stage 1: Builder (No changes)
# ----------------------------------------------------------------------------
ARG TAG=noble
FROM ubuntu:$TAG AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        autoconf \
        build-essential \
        ca-certificates \
        dpkg-dev \
        git \
        libltdl-dev \
        libpulse-dev \
        libtool \
        lsb-release \
        sudo && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/neutrinolabs/pulseaudio-module-xrdp.git /pulseaudio-module-xrdp
WORKDIR /pulseaudio-module-xrdp
RUN scripts/install_pulseaudio_sources_apt.sh && \
    ./bootstrap && \
    ./configure PULSE_DIR=$HOME/pulseaudio.src && \
    make && \
    make install DESTDIR=/tmp/install

# ----------------------------------------------------------------------------
# Stage 2: Final Image
# ----------------------------------------------------------------------------
FROM ubuntu:$TAG

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8

# 1. Install specific requirements for the Setup Phase
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        sudo \
    && rm -rf /var/lib/apt/lists/*

# 2. Setup Mozilla Repo, Pinning, Install Desktop & Clean up
RUN install -d -m 0755 /etc/apt/keyrings && \
    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null && \
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" > /etc/apt/sources.list.d/mozilla.list && \
    echo "Package: *" > /etc/apt/preferences.d/mozilla && \
    echo "Pin: origin packages.mozilla.org" >> /etc/apt/preferences.d/mozilla && \
    echo "Pin-Priority: 1000" >> /etc/apt/preferences.d/mozilla && \
    \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        dbus-x11 \
        firefox \
        iproute2 \
        iputils-ping \
        locales \
        pavucontrol \
        pulseaudio \
        pulseaudio-utils \
        x11-xserver-utils \
        xfce4 \
        xfce4-pulseaudio-plugin \
        xfce4-terminal \
        librsvg2-common \
        xorgxrdp \
        xrdp \
    && \
    locale-gen en_US.UTF-8 && \
    apt-get purge -y --auto-remove wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    userdel -r ubuntu

COPY --from=builder /tmp/install /
RUN sed -i 's|^Exec=.*|Exec=/usr/bin/pulseaudio|' /etc/xdg/autostart/pulseaudio-xrdp.desktop

COPY entrypoint.sh /usr/bin/entrypoint
EXPOSE 3389/tcp
ENTRYPOINT ["/usr/bin/entrypoint"]