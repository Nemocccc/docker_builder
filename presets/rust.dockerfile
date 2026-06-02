ARG BASE_IMAGE=rust:1-trixie
FROM ${BASE_IMAGE}

<EMBED _common.dockerfile>

# rust 工具链已在 base 中；以下确保非 root 用户可写 cargo / rustup
USER root
RUN mkdir -p /usr/local/cargo /usr/local/rustup \
    && chown -R vscode:vscode /usr/local/cargo /usr/local/rustup
USER vscode
ENV CARGO_HOME=/usr/local/cargo
ENV RUSTUP_HOME=/usr/local/rustup
ENV PATH="/usr/local/cargo/bin:$PATH"