# 安装使用指南

## 前置要求

- **Node.js 22+**（推荐使用 LTS 版本）
- **macOS** 系统（本指南基于 MacBook Air M4）
- **Chrome 浏览器**

```bash
# 检查 Node.js 版本
node --version

# 如果版本低于 22，建议使用 nvm 安装
# curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
# nvm install 22
# nvm use 22
```

## 第一步：安装 OpenClaw

```bash
# 安装 OpenClaw
curl -fsSL https://openclaw.ai/install.sh | bash

# 运行引导向导（会自动安装守护进程）
openclaw onboard --install-daemon

# 检查网关状态
openclaw gateway status

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
openclaw logs

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

# 检查端口占用（默认端口 3000）
lsof -i :3000

# 如果端口被占用，可以在配置中修改端口
# 编辑 ~/.openclaw/openclaw.json，添加：
# "gateway": { "port": 3001 }
```

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


