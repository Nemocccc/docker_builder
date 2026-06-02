ARG BASE_IMAGE=node:24-trixie-slim
FROM ${BASE_IMAGE}

<EMBED _common.dockerfile>

USER vscode
RUN npm install -g pnpm
ENV PNPM_HOME="/home/vscode/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"