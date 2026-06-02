# docker-builder

A small CLI to scaffold a dev environment (`.devcontainer/devcontainer.json` + `Dockerfile`) from one or more stacked recipe presets. Stdlib only — no pip, no brew, no extra dependencies.

Backed by the [dev container spec](https://containers.dev/) and the [devcontainer CLI](https://github.com/devcontainers/cli).

## Quick start

```bash
./install.sh                                  # install devcontainer CLI + symlink docker-builder
docker-builder list                           # see available presets
docker-builder doctor                         # check docker / devcontainer CLI / network
docker-builder new myapp --preset python      # single preset (python 3.14 + uv)
docker-builder new myapp --preset python cpp  # stack: python base + cpp toolchain
docker-builder new                            # minimal: just _common (git/sudo/vscode user)
cd myapp && docker-builder up                 # build + start + attach shell automatically
docker-builder down                           # stop and remove the container
```

## Presets

| preset      | base image                    | tools                                |
|-------------|-------------------------------|--------------------------------------|
| `base`      | `debian:13-slim`              | (no extras)                          |
| `python`    | `python:3.14-slim-trixie`     | + uv                                 |
| `node-vite` | `node:24-trixie-slim`         | + pnpm                               |
| `rust`      | `rust:1-trixie`               | (rust toolchain)                     |
| `go`        | `golang:1.26-trixie`          | (go toolchain)                       |
| `cpp`       | `debian:13-slim`              | + build-essential, cmake, gdb, clang, ninja |

Omit `--preset` to get just the `_common` fragment (git, sudo, vscode user, no FROM/base image — useful as a starting point you'll fill in yourself).

## Stacking multiple presets

The first preset determines the `FROM` line. Subsequent presets add their toolchain `RUN` blocks to the same base image — no multi-stage, just stacked layers. This matches the legacy hand-rolled prototype's "Input image layers you want" model.

```bash
docker-builder new myapp --preset python cpp          # python base + cpp toolchain
docker-builder new myapp --preset python cpp rust     # 3-language stack
docker-builder new myapp --preset rust python         # rust base + python (rust wins as FROM)
```

Duplicate preset names are rejected:
```bash
$ docker-builder new x --preset python python
✗ duplicate preset 'python' in --preset. list: ['python', 'python']
```

## How it works

Each preset is two files under `presets/`:
- `<id>.dockerfile` — Dockerfile fragment (with `<EMBED _common.dockerfile>` placeholder)
- `<id>.json` — devcontainer.json fields

At `new` time, `docker-builder`:
1. Embeds `_common.dockerfile` between the first preset and the rest.
2. Drops the `ARG BASE_IMAGE` / `FROM ${BASE_IMAGE}` lines from the 2nd+ presets (they share the first preset's base).
3. Merges `_common.json` with the first preset's JSON (preset wins), then appends list fields (`vscode.extensions`, `forwardPorts`) from the rest.
4. Writes both to `<name>/.devcontainer/`.

The generated `ARG BASE_IMAGE` line at the top is intentional: devcontainer CLI injects `--image` into it, which suppresses the `InvalidDefaultArgInFrom` BuildKit warning.

Edit the generated `Dockerfile` and `devcontainer.json` freely — `docker-builder` never overwrites user changes (use `--force` to bypass).

## Commands

```
docker-builder list                                    # show all presets
docker-builder doctor                                  # check docker / devcontainer CLI / network
docker-builder new <name> --preset A [B C...] [--output DIR] [--here] [--force]
docker-builder init  --preset A [B C...]               # alias for `new --here` in cwd
docker-builder up    [path] [--name NAME] [--no-exec]  # build + start + attach (or detach with --no-exec)
docker-builder down  [path]                            # stop + remove container
```

`up` defaults to attaching a shell via `docker exec -it <container> bash` after the container starts. Press Ctrl+D to detach; the container keeps running. Pass `--no-exec` to start in the background and stay in the host shell.

## Requirements

- Docker Engine or Docker Desktop
- macOS or Linux
- `devcontainer` CLI (installed by `install.sh` on first run, with explicit prompt)
- Python 3.9+ (for the script itself, no third-party packages)
