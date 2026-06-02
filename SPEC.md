# docker_builder — 需求规格说明

> Version: 0.1 (draft)
> Status: 设计阶段，等待实现

## 1. 一句话定位

一个终端命令，把一个 JSON / YAML 配方文件（recipe）转成可运行的 Docker 开发环境。体验对标 `npx create-*` / `cargo new` / `npm init`，但产物是 Dockerfile + docker-compose.yml + .dockerignore 一整套，且不依赖任何额外运行时（Python 3.9+ 标准库即可，不装 pip/brew 包）。

## 2. 核心使用方式

### 2.1 最小用例（最常用路径）

```bash
$ docker-builder new myapp --preset python-fastapi
✓ created ./myapp/
  ├── Dockerfile
  ├── docker-compose.yml
  ├── .dockerignore
  └── README.md

$ cd myapp && docker-builder up
# 等价于：docker compose build && docker compose up -d && docker compose exec myapp bash
```

### 2.2 调整配方

```bash
# 生成配方文件，编辑后再生成
$ docker-builder new myapp --preset python-fastapi --emit-recipe
$ vim myapp/docker-builder.json
$ docker-builder apply myapp/docker-builder.json
```

### 2.3 纯模板模式（不想用脚手架目录）

```bash
$ docker-builder render recipe.json -o .
# 在当前目录就地生成 Dockerfile / docker-compose.yml / .dockerignore
```

### 2.4 远程配方（类 npx create-*）

```bash
$ docker-builder new myapp --preset https://raw.githubusercontent.com/foo/bar/recipe.json
$ docker-builder new myapp --from github.com/Nemocccc/recipes/python-ml.json
```

### 2.5 自定义预设

```bash
# 用户级
$ docker-builder preset add myteam https://github.com/myteam/recipes.git
# 项目级
$ docker-builder new myapp --preset myteam/ros2
```

## 3. 命令清单

```
docker-builder
├── new <name>                    创建新项目目录
│   ├── --preset <id>            内置/远程/自定义预设（必填之一）
│   ├── --from <url>             远程配方 URL
│   ├── --emit-recipe            生成配方文件而不直接生成 Dockerfile
│   ├── --output <dir>           输出目录（默认 ./<name>）
│   └── --force                  目录已存在时覆盖
│
├── render <recipe>              渲染配方为 Docker 文件
│   ├── -o, --output <dir>       输出目录
│   └── --dry-run                只打印将要生成的内容
│
├── apply <recipe>               render + up 的组合
│
├── up [name]                    构建并启动，可选 exec 进容器
│   ├── --no-build               跳过 build
│   ├── --no-exec                启动后不 exec 进 shell
│   └── --shell <cmd>            自定义 exec 命令（默认 bash）
│
├── down [name]                  docker compose down
│
├── list                         列出所有内置预设（带描述）
│
├── preset                       预设管理
│   ├── list
│   ├── add <name> <git-url>
│   ├── remove <name>
│   └── update [name]
│
├── init                         在当前目录生成最小 recipe.json
│
└── doctor                       检查环境（docker / compose / 网络/ 镜像源可达性）
```

## 4. 配方（recipe）文件格式

### 4.1 顶层结构

```json
{
  "$schema": "https://raw.githubusercontent.com/Nemocccc/docker_builder/main/schema/recipe.schema.json",
  "version": "1",

  "name": "myapp",
  "description": "FastAPI dev environment",

  "base": {
    "image": "python:3.12-slim",
    "tag_lock": "sha256:...",
    "workdir": "/app",
    "user": "1000:1000"
  },

  "mirrors": {
    "apt": "https://mirrors.tuna.tsinghua.edu.cn/ubuntu/",
    "pip": "https://pypi.tuna.tsinghua.edu.cn/simple",
    "npm": "https://registry.npmmirror.com",
    "cargo": "https://rsproxy.cn/crates.io-index",
    "go": "https://goproxy.cn,direct"
  },

  "system_packages": ["git", "curl", "build-essential"],

  "languages": {
    "python": {
      "manager": "uv",
      "version": "3.12",
      "deps": ["fastapi", "uvicorn[standard]"],
      "lockfile": "uv.lock"
    },
    "node": {
      "manager": "pnpm",
      "version": "20",
      "deps": ["react", "react-dom"]
    }
  },

  "tools": ["git", "docker-in-docker", "sshd"],

  "ports": ["8000:8000", "5173:5173"],

  "volumes": ["./:/app", "~/.ssh:/home/dev/.ssh:ro"],

  "env": {
    "PYTHONUNBUFFERED": "1",
    "PYTHONDONTWRITEBYTECODE": "1"
  },

  "security": {
    "privileged": false,
    "network_mode": "bridge",
    "ipc": "private",
    "cap_drop": ["ALL"],
    "cap_add": ["NET_ADMIN"]
  },

  "compose_extensions": {
    "depends_on": ["db"],
    "extra_services": {
      "db": { "image": "postgres:16", "volumes": ["pgdata:/var/lib/postgresql/data"] }
    }
  }
}
```

### 4.2 设计原则

- **JSON 优先，YAML 兼容**（YAML 解析用 stdlib + 简单手写解析，避开 PyYAML 依赖）
- **未知字段直接报错**，不让用户写错配置还自以为对
- **可裁剪**：用户可以只写 `name` + `preset` 两行，其余走默认值
- **可组合**：`languages` 是个对象而不是数组，所以 `python` / `node` / `rust` 可同时存在

## 5. 内置预设清单

每个预设都是一个独立的 `.json` 文件，存放在 `presets/` 目录。

### 5.1 通用开发

| ID | 用途 |
|----|------|
| `python-base` | 裸 python（uv 管理依赖） |
| `python-fastapi` | FastAPI + uvicorn |
| `python-django` | Django + postgres 配套 |
| `python-ml` | python + cuda 基础镜像（multi-stage） |
| `python-datascience` | jupyter + numpy/pandas/sklearn |
| `node-base` | node + pnpm |
| `node-react-vite` | React + Vite，HMR 友好 |
| `node-nextjs` | Next.js + 端口 3000 |
| `node-nestjs` | NestJS + postgres |
| `rust-base` | multi-stage，slim runtime |
| `go-base` | multi-stage，scratch/alpine runtime |
| `cpp-base` | gcc/cmake/conan |
| `c-base` | 纯 C + make |

### 5.2 工具类

| ID | 用途 |
|----|------|
| `git` | 基础 + git 配置挂载 |
| `docker-in-docker` | 容器内可跑 docker（适合 CI） |
| `sshd` | 提供 SSH 入口 |
| `ros2-humble` | ROS2 Humble 全套 |
| `cuda` | nvidia/cuda 基础镜像 |
| `r-dev` | R + tidyverse |

### 5.3 组合预设

| ID | 用途 |
|----|------|
| `llm-train` | python-ml + cuda + docker-in-docker |
| `web-fullstack` | node-react-vite + python-fastapi + postgres |

每个预设可声明 `extends: ["python-base", "git"]`，自动继承并合并字段。

## 6. 渲染输出

每个项目目录生成四个文件：

### 6.1 `Dockerfile`

- base image 必填，digest 可选但推荐
- 所有 `system_packages` 合并为一个 RUN 层（一次 apt-get update + 一次 install + 一次 clean）
- 每种语言一个独立 layer（缓存粒度合理）
- multi-stage 自动应用（rust / go / 任何带 `runtime_image` 字段的语言）
- 默认包含 `HEALTHCHECK`、`LABEL maintainer`
- 末尾暴露端口、定义 ENTRYPOINT/CMD

### 6.2 `docker-compose.yml`

- 服务名 = recipe.name
- build context 默认 `.`
- volumes / ports / env / security 配置全部翻译为 compose 字段
- `extra_services` 单独成 services 块
- 默认 `restart: unless-stopped`，**不**默认 privileged / network host / ipc host

### 6.3 `.dockerignore`

- 根据 `volumes` 字段反推：被挂载进容器的宿主路径必须保留，其他都忽略
- 永远忽略：`.git`、`.venv`/`venv`、`__pycache__`、`node_modules`、`target`、`build`、`dist`、`.DS_Store`、`*.log`
- 用户可显式追加 `ignore: ["secrets.env"]` 字段

### 6.4 `README.md`

- 项目名、描述
- 一行复制粘贴的 `docker-builder up` 命令
- 端口列表、卷挂载说明
- 配方文件位置 + 编辑后 `docker-builder apply` 提示

## 7. 用户体验细节

- **彩色输出**（stderr 走 `sys.stderr`，TTY 感知自动关色）
- **进度反馈**：每生成一个文件打印一行 `✓ created Dockerfile`
- **错误友好**：
  - 未知字段：`error: unknown field "mrrors" in base, did you mean "mirrors"?`
  - 配方语法错误：显示行号 + 上下文
  - docker / compose 不可用：`error: docker not found. install from https://docs.docker.com/get-docker/`
- **幂等**：重复运行 `apply` 不会污染源文件
- **不破坏现状**：`new` 默认拒绝覆盖已有目录，加 `--force` 才覆盖
- **干跑**：`render --dry-run` 把所有文件打印到 stdout，方便 review

## 8. 非功能需求

### 8.1 安装

- **零依赖安装**：clone 后 `chmod +x docker_builder.py && ln -s $PWD/docker_builder.py ~/bin/docker-builder` 即可
- **可 pip 安装**：`pip install .` 也行，但**不是首选**（用户偏好：尽量不装包）
- 提供 `install.sh` 一键创建 symlink 到 `~/bin`

### 8.2 兼容性

- Python 3.9+
- macOS 12+ 和 Linux x86_64 / arm64
- Docker Engine 20.10+ / Docker Compose v2（不兼容 v1 语法）
- 网络环境自适应：能访问外网走官方源，否则 fallback 到 `mirrors` 字段

### 8.3 性能

- 渲染 < 200ms（无网络）
- `up` 启动时间主要在 docker 自身，工具不增加开销

### 8.4 安全

- 拉取远程配方走 HTTPS，不接受 HTTP
- 配方 URL 允许 `--insecure` 跳过校验（不推荐，明确警告）
- 不执行配方内嵌的任意 shell（配方只是数据，不含 `script` 字段）

## 9. 明确不做的事

- ❌ 不做镜像推送 / 部署（只做本地 dev 环境）
- ❌ 不做容器管理面板（CLI 即可）
- ❌ 不做 Kubernetes 支持
- ❌ 不支持 Docker Compose v1 语法
- ❌ 不内置 GPU / CUDA 检测逻辑（用户自己知道要不要 cuda preset）
- ❌ 不做 GUI / TUI（v0.1 范围内）

## 10. 里程碑

- **v0.1（MVP）**：`new` / `render` / `up` / `down` / 内置 4 个预设（python-base / node-base / rust-base / go-base）
- **v0.2**：远程配方 + preset add/remove + --emit-recipe
- **v0.3**：完整 5.x 预设清单 + extends 机制 + schema 校验
- **v0.4**：doctor 环境检测 + 自动镜像源探测
- **v1.0**：稳定 schema + 远程 preset 仓库协议 + 文档站

## 11. 开放问题

1. 是否需要支持 `Dockerfile` 片段插入（用户自定义 RUN）？倾向不做，配方已经够灵活
2. `apt` 镜像源字段用 URL 还是 codename（`jammy` / `noble`）？倾向 codename + URL 双格式
3. 是否提供 `doctor` 的自动修复？倾向 v1.0 再加
4. 配方的 `$schema` 校验在 v0.1 阶段是软警告还是硬错误？倾向硬错误
