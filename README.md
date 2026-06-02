# docker-builder

A small CLI to scaffold a dev environment (`.devcontainer/devcontainer.json` + `Dockerfile`) from a built-in recipe preset. Stdlib only — no pip, no brew, no extra dependencies.

Backed by the [dev container spec](https://containers.dev/) and the [devcontainer CLI](https://github.com/devcontainers/cli).

## Quick start

```bash
./install.sh                     # install devcontainer CLI + symlink docker-builder
docker-builder list              # see available presets
docker-builder new myapp --preset python
cd myapp && docker-builder up    # build and attach into the dev container
docker-builder down              # stop and remove the container
```

## Presets

| preset      | base image                    | tools                      |
|-------------|-------------------------------|----------------------------|
| `base`      | `debian:13-slim`              | git, sudo                  |
| `python`    | `python:3.14-slim-trixie`     | + uv                       |
| `node-vite` | `node:24-trixie-slim`         | + pnpm                     |
| `rust`      | `rust:1-trixie`               | (rust toolchain)           |
| `go`        | `golang:1.26-trixie`          | (go toolchain)             |
| `cpp`       | `debian:13-slim`              | + cmake, gdb, clang, ninja |

## How it works

Each preset is two files under `presets/`:
- `<id>.dockerfile` — Dockerfile fragment (with `<EMBED _common.dockerfile>` placeholder)
- `<id>.json` — devcontainer.json fields

At `new` time, `docker-builder`:
1. Inlines `_common.dockerfile` into the placeholder.
2. Merges `_common.json` with the preset JSON.
3. Writes both to `<name>/.devcontainer/`.

Edit the generated `Dockerfile` and `devcontainer.json` freely — `docker-builder` never overwrites user changes.

## Commands

```
docker-builder list                    # show all presets
docker-builder new <name> --preset <id> [--output DIR] [--force]
docker-builder init  --preset <id>     # generate in current dir
docker-builder up    [path]            # devcontainer up (attaches shell)
docker-builder down  [path]            # stop + remove container
```

## Requirements

- Docker Engine or Docker Desktop
- macOS or Linux
- `devcontainer` CLI (installed by `install.sh` on first run, with explicit prompt)
- Python 3.9+ (for the script itself, no third-party packages)

## See also

- `SPEC.md` — full design rationale
- `.old/` — earlier hand-rolled bash prototype (kept for reference, not used at runtime)
