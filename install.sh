#!/usr/bin/env bash
# install.sh — one-shot setup for docker-builder
# - installs devcontainer CLI to ~/.devcontainers/bin (no sudo)
# - symlinks docker-builder into ~/bin
# - adds both to PATH in ~/.zshrc / ~/.bashrc (idempotent)
set -euo pipefail

DOCKER_BUILDER_SRC="$(cd "$(dirname "$0")" && pwd)/docker-builder"
DOCKER_BUILDER_LINK="${HOME}/bin/docker-builder"
DCC_BIN_DIR="${HOME}/.devcontainers/bin"

# 1. symlink docker-builder
mkdir -p "${HOME}/bin"
if [[ -L "${DOCKER_BUILDER_LINK}" ]] || [[ -e "${DOCKER_BUILDER_LINK}" ]]; then
    echo "→ ${DOCKER_BUILDER_LINK} already exists, replacing"
    rm -f "${DOCKER_BUILDER_LINK}"
fi
ln -s "${DOCKER_BUILDER_SRC}" "${DOCKER_BUILDER_LINK}"
chmod +x "${DOCKER_BUILDER_SRC}"
echo "✓ linked ${DOCKER_BUILDER_LINK} -> ${DOCKER_BUILDER_SRC}"

# 2. install devcontainer CLI (only if missing)
if ! command -v devcontainer >/dev/null 2>&1; then
    echo "→ installing devcontainer CLI to ${DCC_BIN_DIR}"
    curl -fsSL https://raw.githubusercontent.com/devcontainers/cli/main/scripts/install.sh | sh
else
    echo "✓ devcontainer CLI already on PATH"
fi

# 3. ensure PATH exports are in shell rc files
add_path() {
    local rcfile="$1"
    local line="$2"
    [[ -f "${rcfile}" ]] || return 0
    if grep -qF "${line}" "${rcfile}"; then
        return 0
    fi
    printf "\n# docker-builder\n%s\n" "${line}" >> "${rcfile}"
    echo "✓ added PATH export to ${rcfile}"
}

add_path "${HOME}/.zshrc" 'export PATH="${HOME}/bin:${HOME}/.devcontainers/bin:${PATH}"'
add_path "${HOME}/.bashrc" 'export PATH="${HOME}/bin:${HOME}/.devcontainers/bin:${PATH}"'

echo ""
echo "open a new shell, or run:"
echo "    export PATH=\"\${HOME}/bin:\${HOME}/.devcontainers/bin:\${PATH}\""
echo "then: docker-builder list"
