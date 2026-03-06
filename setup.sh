#!/usr/bin/env bash
# ┌──────────────────────────────────────────────────────────────────┐
# │  OpenClaw Docker 一键安装脚本                                    │
# │  MacBook Air M4 安全加固版                                       │
# └──────────────────────────────────────────────────────────────────┘
set -euo pipefail

# ── 颜色输出 ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail()  { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW_REPO_DIR="$SCRIPT_DIR/openclaw"
ENV_FILE="$SCRIPT_DIR/.env"

# ══════════════════════════════════════════════
#  1. 前置检查
# ══════════════════════════════════════════════
info "检查前置依赖..."

# 检查 Docker
if ! command -v docker &>/dev/null; then
  fail "未检测到 Docker。请先安装 Docker Desktop for Mac:\n    https://docs.docker.com/desktop/install/mac-install/"
fi

# 检查 Docker 是否运行
if ! docker info &>/dev/null; then
  fail "Docker Desktop 未运行。请先启动 Docker Desktop。"
fi

# 检查 Docker Compose v2
if ! docker compose version &>/dev/null; then
  fail "未检测到 Docker Compose v2。请更新 Docker Desktop 到最新版本。"
fi

# 检查 Git
if ! command -v git &>/dev/null; then
  fail "未检测到 Git。请安装: xcode-select --install"
fi

ok "所有依赖已就绪"

# ══════════════════════════════════════════════
#  2. 克隆 / 更新 OpenClaw 源码
# ══════════════════════════════════════════════
if [[ -d "$OPENCLAW_REPO_DIR/.git" ]]; then
  info "OpenClaw 仓库已存在，拉取最新代码..."
  git -C "$OPENCLAW_REPO_DIR" pull --ff-only || warn "拉取失败，使用现有代码继续"
else
  info "克隆 OpenClaw 仓库..."
  git clone --depth 1 https://github.com/openclaw/openclaw.git "$OPENCLAW_REPO_DIR"
fi
ok "OpenClaw 源码就绪"

# ══════════════════════════════════════════════
#  3. 构建 Docker 镜像
# ══════════════════════════════════════════════
info "构建 Docker 镜像 (首次约需 3-5 分钟)..."
docker build \
  --tag openclaw:local \
  --file "$OPENCLAW_REPO_DIR/Dockerfile" \
  "$OPENCLAW_REPO_DIR"
ok "Docker 镜像构建完成"

# ══════════════════════════════════════════════
#  4. 创建数据目录
# ══════════════════════════════════════════════
OPENCLAW_CONFIG_DIR="$HOME/.openclaw"
OPENCLAW_WORKSPACE_DIR="$HOME/openclaw/workspace"

info "创建数据目录..."
mkdir -p "$OPENCLAW_CONFIG_DIR"
mkdir -p "$OPENCLAW_WORKSPACE_DIR"
ok "数据目录已创建:"
echo "    配置: $OPENCLAW_CONFIG_DIR"
echo "    工作空间: $OPENCLAW_WORKSPACE_DIR"

# ══════════════════════════════════════════════
#  5. 生成 .env 文件
# ══════════════════════════════════════════════
if [[ -f "$ENV_FILE" ]]; then
  warn ".env 文件已存在，跳过生成（如需重新生成请先删除 .env）"
  # 从现有 .env 读取 token
  OPENCLAW_GATEWAY_TOKEN=$(grep -E '^OPENCLAW_GATEWAY_TOKEN=' "$ENV_FILE" | cut -d'=' -f2 || true)
else
  info "生成安全认证令牌..."
  OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)

  cat > "$ENV_FILE" <<EOF
# 由 setup.sh 自动生成 - $(date '+%Y-%m-%d %H:%M:%S')
# ⚠️ 此文件包含敏感信息，请勿提交到 Git

OPENCLAW_GATEWAY_TOKEN=${OPENCLAW_GATEWAY_TOKEN}
OPENCLAW_CONFIG_DIR=${OPENCLAW_CONFIG_DIR}
OPENCLAW_WORKSPACE_DIR=${OPENCLAW_WORKSPACE_DIR}
OPENCLAW_GATEWAY_PORT=18789
OPENCLAW_BRIDGE_PORT=18790
OPENCLAW_GATEWAY_BIND=lan
OPENCLAW_IMAGE=openclaw:local
EOF
  ok ".env 文件已生成"
fi

# ══════════════════════════════════════════════
#  6. 修复数据目录权限
# ══════════════════════════════════════════════
info "修复容器内目录权限..."
docker compose -f "$SCRIPT_DIR/docker-compose.yml" --env-file "$ENV_FILE" \
  run --rm --user root --entrypoint sh openclaw-gateway -c \
  'find /home/node/.openclaw -xdev -exec chown node:node {} + 2>/dev/null; \
   [ -d /home/node/.openclaw/workspace/.openclaw ] && chown -R node:node /home/node/.openclaw/workspace/.openclaw || true'
ok "权限修复完成"

# ══════════════════════════════════════════════
#  7. 运行 Onboarding (交互式)
# ══════════════════════════════════════════════
echo ""
info "启动 Onboarding 向导..."
info "按照提示配置 AI 模型和 API Key"
echo ""
docker compose -f "$SCRIPT_DIR/docker-compose.yml" --env-file "$ENV_FILE" \
  run --rm --profile cli openclaw-cli onboard --mode local --no-install-daemon

# ══════════════════════════════════════════════
#  8. 启动 Gateway
# ══════════════════════════════════════════════
echo ""
info "启动 OpenClaw Gateway..."
docker compose -f "$SCRIPT_DIR/docker-compose.yml" --env-file "$ENV_FILE" \
  up -d openclaw-gateway

# 等待健康检查
info "等待服务就绪..."
for i in $(seq 1 30); do
  if docker compose -f "$SCRIPT_DIR/docker-compose.yml" --env-file "$ENV_FILE" \
    ps --format json 2>/dev/null | grep -q '"healthy"'; then
    break
  fi
  sleep 2
done

# ══════════════════════════════════════════════
#  完成！
# ══════════════════════════════════════════════
echo ""
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ OpenClaw 安装完成！${NC}"
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo ""
echo -e "  🌐 Control UI:  ${CYAN}http://127.0.0.1:18789${NC}"
echo -e "  🔑 Gateway Token:"
echo -e "     ${YELLOW}${OPENCLAW_GATEWAY_TOKEN}${NC}"
echo ""
echo -e "  📋 常用命令:"
echo -e "     查看状态:  ${CYAN}docker compose -f $SCRIPT_DIR/docker-compose.yml ps${NC}"
echo -e "     查看日志:  ${CYAN}docker compose -f $SCRIPT_DIR/docker-compose.yml logs -f${NC}"
echo -e "     停止服务:  ${CYAN}docker compose -f $SCRIPT_DIR/docker-compose.yml down${NC}"
echo -e "     重启服务:  ${CYAN}docker compose -f $SCRIPT_DIR/docker-compose.yml restart${NC}"
echo ""
echo -e "  ⚠️  请妥善保管上方 Gateway Token，它是你的访问密码"
echo -e "  ⚠️  首次使用请在 Control UI 中粘贴此 Token 进行认证"
echo ""
