# 安装使用指南

## 前置要求

- **Node.js 22+**（推荐使用 LTS 版本）
- **macOS** 系统（本指南基于 MacBook Air M4）
- **Chrome 浏览器**

```bash
# 检查 Node.js 版本
node --version

# 如果版本低于 22，建议优先安装系统 Node（Homebrew/系统包管理器）
# 说明：网关服务更稳定地依赖系统 Node；如使用 nvm，升级后可能需要重新安装/修复网关服务
# 示例（Homebrew）:
# brew install node@22
```

## 第一步：安装 OpenClaw

```bash
# 安装 OpenClaw
curl -fsSL https://openclaw.ai/install.sh | bash

# 运行引导向导（会自动安装网关服务）
openclaw onboard --install-daemon

# 或者仅安装网关服务（不跑引导向导）
openclaw gateway install

# 检查网关状态
openclaw gateway status

# 如果提示 "pairing required"，先完成设备配对（将本机 CLI 注册为受信任设备）：
openclaw dashboard   # 打开控制台完成配对（或在浏览器里手动打开输出的 URL）

# 或者直接在终端批准最新配对请求：
openclaw devices approve --latest

# 查看版本信息
openclaw --version
```

### 常用命令

```bash
# 启动网关
openclaw gateway start

# 停止网关
openclaw gateway stop

# 重启网关
openclaw gateway restart

# 查看日志
openclaw logs   # 需要已完成配对，否则会提示 pairing required

# 查看配置文件位置
openclaw config file
```

## 使用示例

### 基本使用流程

```bash
# 1. 确保网关正在运行
openclaw gateway status

# 2. 打开 Chrome 浏览器，访问你想让 OpenClaw 读取的网页
# 例如：https://github.com

# 3. 点击 Chrome 工具栏中的 OpenClaw 扩展图标，授权该标签页

# 4. 使用 OpenClaw CLI 与浏览器交互
openclaw browser open https://github.com  # 让浏览器打开网页
openclaw browser status                   # 检查浏览器连接状态
```

## 高级配置

### 日志级别调整

```jsonc
{
  "logging": {
    "level": "info",           // 可选: debug, info, warn, error
    "file": "~/.openclaw/logs/openclaw.log",
    "maxSize": "10m",          // 单个日志文件最大大小
    "maxFiles": 5              // 保留的日志文件数量
  }
}
```

### 网络代理设置

```jsonc
{
  "proxy": {
    "enabled": true,
    "http": "http://127.0.0.1:7890",
    "https": "http://127.0.0.1:7890",
    "bypass": ["localhost", "127.0.0.1"]
  }
}
```

### 超时和重试配置

```jsonc
{
  "browser": {
    "timeout": 30000,          // 页面加载超时（毫秒）
    "retries": 3,              // 失败重试次数
    "retryDelay": 1000         // 重试延迟（毫秒）
  }
}
```

### 完整配置示例

```jsonc
{
  // 浏览器配置
  "browser": {
    "enabled": true,
    "defaultProfile": "chrome",
    "attachOnly": true,
    "evaluateEnabled": false,
    "headless": false,
    "timeout": 30000,
    "retries": 3,
    "retryDelay": 1000,
    "ssrfPolicy": {
      "dangerouslyAllowPrivateNetwork": false,
      "hostnameAllowlist": ["*.google.com", "*.github.com", "*.stackoverflow.com"]
    }
  },

  // 工具权限
  "tools": {
    "deny": ["exec"],
    "exec": {
      "security": "deny"
    }
  },

  // 网关配置
  "gateway": {
    "port": 3000,
    "host": "127.0.0.1",
    "cors": {
      "enabled": true,
      "origins": ["http://localhost:*"]
    }
  },

  // 日志配置
  "logging": {
    "level": "info",
    "file": "~/.openclaw/logs/openclaw.log",
    "maxSize": "10m",
    "maxFiles": 5
  },

  // 代理配置（可选）
  "proxy": {
    "enabled": false,
    "http": "http://127.0.0.1:7890",
    "https": "http://127.0.0.1:7890"
  }
}
```

## 常见问题排查

### 网关无法启动

```bash
# 查看详细日志
openclaw logs --follow

# 检查端口占用（默认端口通常为 3000，具体以 "openclaw gateway status" 输出为准）
# 例如：
# lsof -i :3000

# 如果端口被占用，可以在配置中修改端口
# 编辑 ~/.openclaw/openclaw.json，添加：
# "gateway": { "port": 3001 }
```

### LLM request timed out

出现该提示时，通常是模型提供商的网络不可达、API Key 无效，或未正确配置认证/代理。可按以下顺序排查：

1) 确认模型和认证已配置
```bash
openclaw models list
openclaw models auth add
openclaw models auth order set --provider google google:manual
openclaw gateway restart
```

2) 如果本地网络需要代理（例如访问 Google 模型），只给 OpenClaw 服务配置代理（避免影响全局环境）：
```bash
/usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:HTTP_PROXY string http://127.0.0.1:7890" \
  -c "Add :EnvironmentVariables:HTTPS_PROXY string http://127.0.0.1:7890" \
  -c "Add :EnvironmentVariables:ALL_PROXY string socks5://127.0.0.1:7890" \
  ~/Library/LaunchAgents/ai.openclaw.gateway.plist

openclaw gateway restart
```
注意：若执行 `openclaw gateway install --force` 或重装服务，LaunchAgent 会被重写，需重新添加上述代理变量。

3) 仍然超时，建议更换可用的模型提供商或检查 API Key 状态/限流。

### Chrome 扩展无法连接

```bash
# 1. 确认网关正在运行
openclaw gateway status

# 2. 检查 Chrome 是否允许扩展访问本地服务器
# 打开 chrome://extensions → OpenClaw → 详细信息
# 确保"允许访问文件网址"已开启

# 3. 重新加载扩展
# chrome://extensions → OpenClaw → 点击刷新图标
```

### 配置不生效

```bash
# 验证 JSON 格式是否正确
cat ~/.openclaw/openclaw.json | python3 -m json.tool

# 如果有语法错误，会显示错误信息
# 修复后重启网关
openclaw gateway restart
```
