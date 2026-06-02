ARG BASE_IMAGE=debian:13-slim
FROM ${BASE_IMAGE}

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