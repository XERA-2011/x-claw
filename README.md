# 🦞 x-claw — OpenClaw Docker 部署

MacBook Air M4 上安全运行 [OpenClaw](https://github.com/openclaw/openclaw) 的 Docker 配置。

## 前置条件

- **Docker Desktop for Mac** — [下载安装](https://docs.docker.com/desktop/install/mac-install/)
- **Git** — 一般 macOS 已自带，如需安装运行 `xcode-select --install`

## 快速开始

### 方式一：一键安装

```bash
chmod +x setup.sh
./setup.sh
```

脚本会自动完成：克隆源码 → 构建镜像 → 创建目录 → 生成令牌 → Onboarding → 启动

### 方式二：手动安装

```bash
# 1. 克隆 OpenClaw 源码
git clone --depth 1 https://github.com/openclaw/openclaw.git

# 2. 构建 Docker 镜像
docker build -t openclaw:local -f openclaw/Dockerfile openclaw/

# 3. 创建必要目录
mkdir -p ~/.openclaw ~/openclaw/workspace

# 4. 配置环境变量（已创建 .env 则跳过）
cp .env.example .env
# 编辑 .env，填入 OPENCLAW_GATEWAY_TOKEN
# 生成令牌: openssl rand -hex 32

# 5. 修复权限
docker compose run --rm --user root --entrypoint sh openclaw-gateway -c \
  'find /home/node/.openclaw -xdev -exec chown node:node {} +'

# 6. 运行 Onboarding（配置 AI 模型和 API Key）
docker compose run --rm --profile cli openclaw-cli onboard --mode local --no-install-daemon

# 7. 启动 Gateway
docker compose up -d openclaw-gateway
```

## 访问

- **Control UI**: http://127.0.0.1:18789
- 首次访问需粘贴 `.env` 中的 `OPENCLAW_GATEWAY_TOKEN` 进行认证

## 常用命令

```bash
# 查看运行状态
docker compose ps

# 查看实时日志
docker compose logs -f openclaw-gateway

# 停止服务
docker compose down

# 重启服务
docker compose restart openclaw-gateway

# 运行 CLI 命令（如添加 Telegram 渠道）
docker compose run --rm --profile cli openclaw-cli channels add --channel telegram --token <token>

# 健康检查
docker compose run --rm --profile cli openclaw-cli doctor

# 更新 OpenClaw
cd openclaw && git pull && cd ..
docker build -t openclaw:local -f openclaw/Dockerfile openclaw/
docker compose up -d openclaw-gateway
```

## 安全措施

| 措施 | 说明 |
|------|------|
| 🔒 端口绑定 | `127.0.0.1` — 仅本机可访问，局域网其他设备无法连接 |
| 🛡️ 权限丢弃 | `cap_drop: ALL` — 容器无任何 Linux 特权能力 |
| 🚫 禁止提权 | `no-new-privileges` — 容器内进程无法获取额外权限 |
| 📂 只读文件系统 | `read_only: true` — 防止未授权写入 |
| 🐋 无 docker.sock | 不挂载宿主机 Docker socket，防止容器逃逸 |
| 🔑 强制认证 | Gateway 必须使用令牌认证 |

## 资源限制

针对 **16GB MacBook Air M4** 优化，OpenClaw 后台运行不影响日常使用：

| 资源 | 限制 | 说明 |
|------|------|------|
| CPU | 最多 2 核 | M4 共 10 核，保留 8 核日常使用 |
| 内存 | 最多 2 GB | 总计 16 GB，保留 14 GB 日常使用 |
| /tmp | 256 MB | 限制临时文件大小 |

## 代理配置

`docker-compose.yml` 默认通过 `host.docker.internal:7890` 使用宿主机代理，如需修改可在 `.env` 中覆盖：

```env
HTTP_PROXY=http://host.docker.internal:你的端口
HTTPS_PROXY=http://host.docker.internal:你的端口
ALL_PROXY=socks5://host.docker.internal:你的端口
```

如不需要代理，在 `docker-compose.yml` 中删除相关环境变量即可。

## 文件结构

```
x-claw/
├── docker-compose.yml   # Docker Compose 配置（安全加固）
├── .env.example         # 环境变量模板
├── .env                 # 实际环境变量（⚠️ 不提交到 Git）
├── .gitignore           # 排除敏感文件
├── setup.sh             # 一键安装脚本
├── openclaw/            # OpenClaw 源码（克隆后出现）
└── README.md            # 本文档
```