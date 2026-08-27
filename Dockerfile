FROM ubuntu

WORKDIR /workdir
ENV PATH="/root/go/bin:/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:/usr/local/cargo/bin:$PATH:/root/.local/bin"
ENV IS_SANDBOX=1
ENV GOPATH=/root/go
RUN echo 'alias c="claude --dangerously-skip-permissions"' >> /root/.bashrc


RUN apt-get update && apt-get install -y curl zip unzip wget python3 git python3-setuptools python3-pip maven jq build-essential file xxd gcc-mingw-w64-i686-win32 wine wine64 xvfb imagemagick gcc-mingw-w64-i686 mingw-w64-tools autoconf automake libtool make clang-tidy clang-format tmux screen gdb gdb-mingw-w64 gdb-mingw-w64-target nodejs npm xdotool openjdk-21-jdk maven iputils-ping netcat-openbsd postgresql-client ocaml ocaml-dune z3 cvc4 libgmp-dev pkg-config opam golang-go fluxbox tini nano cmake ninja-build strace
RUN pip3 install --break-system-packages imagehash

RUN git config --global --add safe.directory *

#RUN echo "set -g mouse on" >> /root/.tmux.conf
RUN git config --global --add safe.directory /workdir

RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
RUN echo 'source $HOME/.cargo/env' >> /root/.bashrc
ENV PATH="/usr/local/cargo/bin:/root/.cargo/bin:/root/.local/bin:${PATH}"
RUN rustup component add rustfmt clippy

RUN curl -LsSf https://astral.sh/uv/install.sh | sh

RUN go install honnef.co/go/tools/cmd/staticcheck@latest && go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest

ARG FLUTTER_VERSION=3.24.5
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git /opt/flutter \
    && git config --global --add safe.directory /opt/flutter \
    && flutter config --no-analytics \
    && flutter config --enable-web \
    && flutter precache --web

# Wine deps
RUN apt-get install -y --no-install-recommends \
    bison \
    flex \
    gcc-multilib \
    g++-multilib \
    g++-mingw-w64-i686-posix \
    g++-mingw-w64-i686-win32
RUN dpkg --add-architecture i386 && apt-get update

# 32-bit dev headers
RUN apt-get install -y --no-install-recommends \
    libx11-dev:i386 \
    libxext-dev:i386 \
    libfontconfig1-dev:i386 \
    libfreetype-dev:i386 \
    libxcursor-dev:i386 \
    libxi-dev:i386 \
    libxrender-dev:i386 \
    libxrandr-dev:i386 \
    libxfixes-dev:i386 \
    libxinerama-dev:i386 \
    libxxf86vm-dev:i386 \
    libxcomposite-dev:i386 \
    libxdamage-dev:i386 \
    libxkbcommon-dev:i386 \
    libpulse-dev:i386 \
    libcups2-dev:i386 \
    libgnutls28-dev:i386 \
    libsdl2-dev:i386 \
    libudev-dev:i386 \
    libvulkan-dev:i386 \
    libxml2-dev:i386 \
    libxslt1-dev:i386 \
    libgphoto2-dev:i386 \
    libsane-dev:i386 \
    libusb-1.0-0-dev:i386 \
    libdbus-1-dev:i386 \
    libgstreamer1.0-dev:i386 \
    libgstreamer-plugins-base1.0-dev:i386 \
    libosmesa6-dev:i386

ENV OPAMROOT=/root/.opam
ENV OPAMYES=1
# Put the switch's bin ahead of /usr/bin so its dune (3.24.x) shadows apt's 3.20.2.
ENV PATH="/root/.opam/sail/bin:${PATH}"

# Download sail deps of the current master
RUN opam init --bare --disable-sandboxing -y \
 && opam switch create sail ocaml-system \
 && eval $(opam env --switch=sail --set-switch) \
 && git clone --depth 1 https://github.com/rems-project/sail.git /tmp/sail \
 && opam install /tmp/sail --deps-only -y \
 && rm -rf /tmp/sail \
 && opam clean -a -c

# Reference sail
RUN opam switch create sail-release ocaml-system \
 && opam install sail.0.20.2 --switch=sail-release -y \
 && ln -s /root/.opam/sail-release/bin/sail /usr/local/bin/sail-0.20.2 \
 && opam clean -a -c

RUN echo 'eval $(opam env --switch=sail --set-switch)' >> /root/.bashrc

# Install Claude
RUN curl -fsSL https://claude.ai/install.sh | bash

# Install forgejo-cli
#RUN wget https://codeberg.org/forgejo-contrib/forgejo-cli/releases/download/v0.5.0/forgejo-cli-x86_64-linux.tar.gz && tar -xf forgejo-cli-x86_64-linux.tar.gz && mv fj /usr/local/bin/ && rm forgejo-cli-x86_64-linux.tar.gz
RUN curl https://benni.stronk.pw/benni/fj > /usr/local/bin/fj && chmod +x /usr/local/bin/fj

RUN wget https://github.com/woodpecker-ci/woodpecker/releases/download/v3.18.0/woodpecker-cli_3.18.0_amd64.deb && apt-get install -y "./woodpecker-cli_3.18.0_amd64.deb" && rm woodpecker-cli_3.18.0_amd64.deb

COPY --from=ghcr.io/trolldemorted/ghidra-headless-cli/ghidra-rpc:latest /ghidra-headless-cli /usr/local/bin/ghidra-headless-cli
COPY --from=ghcr.io/trolldemorted/warren:latest /usr/local/bin/warren-cli /usr/local/bin/warren-cli
COPY --from=ghcr.io/trolldemorted/warren:latest /usr/local/bin/rabbit /usr/local/bin/rabbit
COPY --from=ghcr.io/trolldemorted/warren:latest /usr/local/bin/rabbit-hook /usr/local/bin/rabbit-hook

ENTRYPOINT sleep 999999999
