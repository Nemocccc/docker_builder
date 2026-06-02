# 通用片段：所有 preset 都嵌入此段（不含 FROM）
# 由 docker-builder 写入时展开 <EMBED _common.dockerfile> 占位符

USER root
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        sudo \
        curl \
        ca-certificates \
        gnupg \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -s /bin/bash vscode 2>/dev/null || true \
    && echo "vscode ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode

USER vscode
WORKDIR /home/vscode
