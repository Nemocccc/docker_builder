ARG BASE_IMAGE=python:3.14-slim-trixie
FROM ${BASE_IMAGE}

<EMBED _common.dockerfile>

USER vscode
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/home/vscode/.local/bin:$PATH"