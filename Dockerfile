FROM ubuntu

WORKDIR /workdir
ENV PATH="/root/go/bin:/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:/usr/local/cargo/bin:$PATH:/root/.local/bin"
ENV IS_SANDBOX=1
ENV GOPATH=/root/go
RUN echo 'alias c="claude --dangerously-skip-permissions"' >> /root/.bashrc


RUN apt-get update && apt-get install -y curl zip unzip wget python3 git python3-setuptools python3-pip maven jq build-essential file xxd gcc-mingw-w64-i686-win32 wine wine64 xvfb imagemagick gcc-mingw-w64-i686 mingw-w64-tools autoconf automake libtool make clang-tidy clang-format tmux screen gdb gdb-mingw-w64 gdb-mingw-w64-target nodejs npm xdotool openjdk-21-jdk maven iputils-ping netcat-openbsd postgresql-client ocaml ocaml-dune z3 cvc4 libgmp-dev pkg-config opam golang-go fluxbox tini nano

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

# Install Claude
RUN curl -fsSL https://claude.ai/install.sh | bash

# Install forgejo-cli
#RUN wget https://codeberg.org/forgejo-contrib/forgejo-cli/releases/download/v0.5.0/forgejo-cli-x86_64-linux.tar.gz && tar -xf forgejo-cli-x86_64-linux.tar.gz && mv fj /usr/local/bin/ && rm forgejo-cli-x86_64-linux.tar.gz
RUN curl https://benni.stronk.pw/benni/fj > /usr/local/bin/fj && chmod +x /usr/local/bin/fj

COPY --from=ghcr.io/trolldemorted/ghidra-headless-cli/ghidra-rpc:latest /ghidra-headless-cli /usr/local/bin/ghidra-headless-cli
COPY --from=ghcr.io/trolldemorted/warren:latest /usr/local/bin/warren-cli /usr/local/bin/warren-cli
COPY --from=ghcr.io/trolldemorted/warren:latest /usr/local/bin/rabbit /usr/local/bin/rabbit
COPY --from=ghcr.io/trolldemorted/warren:latest /usr/local/bin/rabbit-hook /usr/local/bin/rabbit-hook

ENTRYPOINT sleep 999999999
