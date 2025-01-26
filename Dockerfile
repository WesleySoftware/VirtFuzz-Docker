#NOTE: linux kernel build is failing on newer versions of ubuntu for our selected kernel version
FROM ubuntu:22.04

USER root
ENV USER=root
ENV DEBIAN_FRONTEND=noninteractive

# Install package dependencies.
RUN apt-get update \
    && apt-get install -y \
    apt-utils \
    curl \
    build-essential \
    meson \
    ninja-build

RUN mkdir -p /fuzz
COPY VirtFuzz /fuzz/VirtFuzz
#set the bullseye patched image
ENV IMAGE=/fuzz/VirtFuzz/guestimage/bullseye.img

# Add deb-src entries
RUN echo "deb-src http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb-src http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb-src http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse" >> /etc/apt/sources.list && \
    apt-get update

# Install build dependencies
RUN apt build-dep qemu -y
RUN apt build-dep linux -y
RUN apt install libpcap-dev -y
RUN apt install git -y
RUN apt install python3-dev python3-pip -y

#Build their patched qemu
WORKDIR /fuzz
RUN curl https://download.qemu.org/qemu-8.2.2.tar.xz -o qemu.tar.xz
RUN tar xvJf qemu.tar.xz
RUN mv qemu-8.2.2 qemu
RUN rm -rf /fuzz/qemu.tar.xz
WORKDIR /fuzz/qemu
RUN patch -p1 < /fuzz/VirtFuzz/qemu-patch.patch
RUN mkdir build
WORKDIR /fuzz/qemu/build
RUN ../configure --target-list=x86_64-softmmu
RUN make -j$(nproc)
ENV QEMU=/fuzz/qemu/build/qemu-system-x86_64

##Now we build a patched linux kernel
WORKDIR /fuzz
RUN git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
WORKDIR /fuzz/linux
RUN git checkout v6.0
RUN /fuzz/VirtFuzz/kernel-patches/apply.sh
#Depending on the target, apply the patches to annotate for a specific device
RUN /fuzz/VirtFuzz/kernel-patches/annotate-80211.sh
RUN /fuzz/VirtFuzz/kernel-patches/annotate-bluetooth.sh

# Make the config
RUN make x86_64_defconfig
RUN make kvm_guest.config
RUN ./scripts/kconfig/merge_config.sh -m .config /fuzz/VirtFuzz/kernel-config/base.config

# For example enable KASAN and UBSAN
RUN ./scripts/kconfig/merge_config.sh -m .config /fuzz/VirtFuzz/kernel-config/kasan.config
RUN ./scripts/kconfig/merge_config.sh -m .config /fuzz/VirtFuzz/kernel-config/ubsan.config
RUN make olddefconfig
RUN make -j$(nproc)
ENV KERNEL=/fuzz/linux/arch/x86_64/boot/bzImage

# # Install Rust
RUN curl https://sh.rustup.rs -sSf > /tmp/rustup-init.sh \
    && chmod +x /tmp/rustup-init.sh \
    && sh /tmp/rustup-init.sh -y \
    && rm -rf /tmp/rustup-init.sh
ENV PATH="$PATH:~/.cargo/bin"

# # Install nightly rust.
RUN ~/.cargo/bin/rustup install nightly

#build the fuzzer
WORKDIR /fuzz/VirtFuzz
RUN ~/.cargo/bin/cargo build --release