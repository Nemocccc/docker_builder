FROM debian:13-slim

<EMBED _common.dockerfile>

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        gdb \
        clang \
        ninja-build \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*
USER vscode