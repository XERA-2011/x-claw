# x-claw

自用 OpenClaw Docker 部署。

## 安装

```bash
# 首次安装
chmod +x setup.sh

# 拉代码、构建镜像、初始化配置并启动
./setup.sh
```

Control UI: [http://127.0.0.1:18789](http://127.0.0.1:18789)

## 启动

```bash
# 启动网关
docker compose --env-file .env up -d openclaw-gateway
```

## 常用命令

```bash
# 查看容器状态
docker compose --env-file .env ps

# 持续查看网关日志
docker compose --env-file .env logs -f openclaw-gateway

# 重启网关
docker compose --env-file .env restart openclaw-gateway

# 停止并移除容器
docker compose --env-file .env down

# 查看当前运行的 OpenClaw 版本
docker compose --env-file .env exec -T openclaw-gateway node -p "require('/app/package.json').version"
```

## 更新

```bash
# 进入项目目录
cd /Users/xera/GitHub/x-claw

# 拉取最新 tag
git -C openclaw fetch --tags origin

# 切到目标版本
git -C openclaw switch --detach <tag>

# 构建阶段通过宿主机代理访问外网
export HTTP_PROXY=http://host.docker.internal:7890

# HTTPS 请求走宿主机代理
export HTTPS_PROXY=http://host.docker.internal:7890

# 需要 socks5 时使用宿主机代理
export ALL_PROXY=socks5://host.docker.internal:7890

# 本地和宿主机地址不走代理
export NO_PROXY=localhost,127.0.0.1,host.docker.internal

# 用代理重建 openclaw:local 镜像
docker build \
  --build-arg HTTP_PROXY=$HTTP_PROXY \
  --build-arg HTTPS_PROXY=$HTTPS_PROXY \
  --build-arg ALL_PROXY=$ALL_PROXY \
  --build-arg NO_PROXY=$NO_PROXY \
  -t openclaw:local \
  -f openclaw/Dockerfile \
  openclaw

# 用新镜像启动网关
docker compose --env-file .env up -d openclaw-gateway

# 确认当前运行版本
docker compose --env-file .env exec -T openclaw-gateway node -p "require('/app/package.json').version"
```

## 清理

```bash
# 删除悬空镜像
docker image prune -f

# 删除未使用的构建缓存
docker builder prune -a -f
```

## 备注

- `docker build` 里代理不能写 `127.0.0.1:7890`，要用 `host.docker.internal:7890`
- UI 显示旧版本时，先以容器内版本号为准
