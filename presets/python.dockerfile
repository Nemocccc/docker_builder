FROM python:3.14-slim-trixie

<EMBED _common.dockerfile>

USER vscode
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/home/vscode/.local/bin:$PATH"