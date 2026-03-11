# OpenClaw 本地安装 + 限制权限指南

> 在 MacBook Air M4 上安装 OpenClaw，并限制其只能访问 Chrome 浏览器、只读取信息。

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
openclaw config path
```

## 第二步：配置限制权限

### 编辑配置文件

```bash
# 打开配置文件（如果不存在会自动创建）
nano ~/.openclaw/openclaw.json

# 或使用你喜欢的编辑器
# code ~/.openclaw/openclaw.json
# vim ~/.openclaw/openclaw.json
```

将以下内容写入 `~/.openclaw/openclaw.json`：

```jsonc
{
  // ======== 浏览器配置 ========
  "browser": {
    "enabled": true,
    "defaultProfile": "chrome",       // 使用 Chrome 扩展中继模式（你手动控制哪个标签页被访问）
    "attachOnly": true,               // 不自动启动浏览器，只附加到已运行的 Chrome
    "evaluateEnabled": false,         // 禁止执行任意 JavaScript（防止注入）
    "headless": false,
    "ssrfPolicy": {
      "dangerouslyAllowPrivateNetwork": false   // 禁止访问内网地址
    }
  },

  // ======== 禁用命令执行 ========
  "tools": {
    "deny": ["exec"],                 // 完全禁用 exec（shell 命令执行）工具
    "exec": {
      "security": "deny"              // 双重保险：拒绝所有命令执行
    }
  }
}
```

> [!IMPORTANT]
> **关键限制说明：**
> - `tools.deny: ["exec"]` — 完全禁用 shell 命令执行，OpenClaw 无法运行任何系统命令
> - `browser.attachOnly: true` — OpenClaw 不能自己启动浏览器，只能控制你已打开的 Chrome
> - `browser.evaluateEnabled: false` — 禁止在页面中执行任意 JS
> - `browser.defaultProfile: "chrome"` — 使用 Chrome 扩展中继模式，你手动点击扩展图标选择允许控制的标签页

### 应用配置

```bash
# 保存配置后，重启网关使配置生效
openclaw gateway restart

# 验证配置是否正确加载
openclaw gateway status

# 查看当前配置
openclaw config show
```

## 第三步：安装 Chrome 扩展中继

Chrome 扩展中继模式是最安全的方式，因为**你来决定哪个标签页被控制**。

### 安装步骤

```bash
# 安装扩展（会输出扩展目录路径）
openclaw browser extension install

# 查看扩展安装路径
openclaw browser extension path
```

然后：
1. 打开 Chrome → 地址栏输入 `chrome://extensions`
2. 开启 **开发者模式**（右上角开关）
3. 点击 **加载已解压的扩展程序** → 选择上述命令输出的目录
4. 固定扩展到工具栏（点击拼图图标 → 找到 OpenClaw → 点击图钉）

### 使用方式
- 在你想让 OpenClaw 读取的标签页上，**手动点击扩展图标** → 显示 `ON`
- OpenClaw 只能读取你主动授权的标签页
- 再次点击图标即可断开（显示 `OFF`）

### 测试扩展

```bash
# 1. 打开 Chrome 并访问一个网页
# 2. 点击 OpenClaw 扩展图标授权该标签页
# 3. 运行测试命令
openclaw browser test

# 如果配置正确，应该能看到当前页面的标题和 URL
```

## 安全总结

| 限制项 | 配置方式 | 效果 |
|--------|----------|------|
| **禁止执行系统命令** | `tools.deny: ["exec"]` | 无法运行任何 shell 命令、脚本 |
| **只能用 Chrome** | `defaultProfile: "chrome"` + `attachOnly: true` | 不会启动独立浏览器 |
| **手动授权标签页** | Chrome 扩展中继 | 你点击授权才能访问 |
| **禁止执行页面 JS** | `evaluateEnabled: false` | 无法注入/执行 JavaScript |
| **禁止访问内网** | `dangerouslyAllowPrivateNetwork: false` | 只能访问公网地址 |

> [!TIP]
> 如果你还想进一步限制 OpenClaw 只能访问特定网站，可以在 `ssrfPolicy` 中加上白名单：
> ```jsonc
> "ssrfPolicy": {
>   "dangerouslyAllowPrivateNetwork": false,
>   "hostnameAllowlist": ["*.google.com", "*.github.com"]
> }
> ```

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

### 查看 OpenClaw 可用工具

```bash
# 列出所有可用工具
openclaw tools list

# 应该看不到 "exec" 工具（因为已被禁用）
```

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

## 使用示例

### 基本使用流程

```bash
# 1. 确保网关正在运行
openclaw gateway status

# 2. 打开 Chrome 浏览器，访问你想让 OpenClaw 读取的网页
# 例如：https://github.com

# 3. 点击 Chrome 工具栏中的 OpenClaw 扩展图标，授权该标签页

# 4. 使用 OpenClaw CLI 或 API 与浏览器交互
openclaw browser current-page  # 获取当前页面信息
```

### 通过 API 使用

OpenClaw 提供 HTTP API，可以通过编程方式控制：

```bash
# 获取当前授权页面的信息
curl http://localhost:3000/api/browser/current

# 读取页面内容
curl http://localhost:3000/api/browser/content

# 查看 API 文档
openclaw api docs
```

### 集成到你的应用

```javascript
// Node.js 示例
const axios = require('axios');

async function getCurrentPage() {
  try {
    const response = await axios.get('http://localhost:3000/api/browser/current');
    console.log('当前页面:', response.data);
  } catch (error) {
    console.error('错误:', error.message);
  }
}

getCurrentPage();
```

```python
# Python 示例
import requests

def get_current_page():
    try:
        response = requests.get('http://localhost:3000/api/browser/current')
        print('当前页面:', response.json())
    except Exception as e:
        print('错误:', str(e))

get_current_page()
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

## 安全最佳实践

1. **定期更新**
   ```bash
   # 检查更新
   openclaw update check
   
   # 更新到最新版本
   openclaw update install
   ```

2. **监控日志**
   ```bash
   # 实时查看日志
   openclaw logs --follow
   
   # 搜索可疑活动
   grep -i "error\|warn\|denied" ~/.openclaw/logs/openclaw.log
   ```

3. **限制网络访问**
   - 使用 `hostnameAllowlist` 白名单限制可访问的域名
   - 定期审查授权的标签页
   - 不要在敏感页面（银行、支付等）上授权 OpenClaw

4. **备份配置**
   ```bash
   # 备份配置文件
   cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup
   
   # 恢复配置
   cp ~/.openclaw/openclaw.json.backup ~/.openclaw/openclaw.json
   openclaw gateway restart
   ```

## 参考资源

- [OpenClaw 官方文档](https://docs.openclaw.ai)
- [GitHub 仓库](https://github.com/openclaw/openclaw)
- [安全配置指南](https://docs.openclaw.ai/security)
- [API 参考](https://docs.openclaw.ai/api)
- [社区论坛](https://community.openclaw.ai)

## 许可证

本指南采用 MIT 许可证。OpenClaw 的许可证请参考其官方仓库。
