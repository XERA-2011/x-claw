# 彻底删除指南

## 彻底删除 OpenClaw

### 方式一：一键卸载（推荐）

```bash
openclaw uninstall --all --yes --non-interactive
```

### 方式二：手动清理

如果 `openclaw` 命令已不可用，按以下步骤手动删除：

```bash
# 1. 停止并移除后台服务
launchctl unload ~/Library/LaunchAgents/com.openclaw.gateway.plist 2>/dev/null
launchctl unload ~/Library/LaunchAgents/ai.openclaw.*.plist 2>/dev/null
rm -f ~/Library/LaunchAgents/com.openclaw.gateway.plist
rm -f ~/Library/LaunchAgents/ai.openclaw.*.plist

# 2. 卸载 npm 全局包
npm rm -g openclaw

# 3. 删除配置和数据目录
rm -rf ~/.openclaw
rm -rf ~/.openclaw-*

# 4. 清理历史遗留目录（旧版名称）
rm -rf ~/.clawdbot
rm -rf ~/.moltbot

# 5. 删除 macOS 应用（如有）
rm -rf /Applications/OpenClaw.app
```

### 验证已完全删除

```bash
# 应返回 "command not found"
openclaw --version

# 应无结果
launchctl list | grep -i openclaw

# 应返回 "No such file or directory"
ls ~/.openclaw ~/.openclaw-*

# 检查 npm 全局包
npm list -g openclaw
```

> [!WARNING]
> 如果你曾将 OpenClaw 连接到 OpenAI、Anthropic、Telegram 等第三方服务，记得前往这些平台的安全设置中**撤销 OpenClaw 的访问授权**。
