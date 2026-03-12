# 限制权限指南

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

# 查看配置文件内容
cat ~/.openclaw/openclaw.json
```

## 第三步：使用中继模式与隔离控制

设置了 `defaultProfile: "chrome"` 且 `attachOnly: true` 之后，OpenClaw 将无法自行拉起全新独立的后台浏览器进程。这也是最安全的方式，因为它**只能读取你已经通过远程调试端口（远程调试模式）主动暴露的浏览器环境**。

### 启动可控浏览器实例的推荐方式

你可以在平时上网的浏览器之外，独立启动一个带有调试端口的 Chrome 配合系统使用：

```bash
# 以远程调试模式启动一个干净的 Chrome 实例（端口假设为 9222）
# OpenClaw 将只连接到该实例进行阅读
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222 --user-data-dir=/tmp/chrome_sandbox
```

> 配合 `evaluateEnabled: false` 可以进一步保证即使读取受控页面，也不会被注入执行各种危险的 JS 脚本。

### 测试隔离效果

```bash
# 1. 在上面的独立浏览器中访问一个网页
# 2. 检查系统日志或网关运行状态
openclaw browser status

# 如果发现无法读取，说明它被正确隔离了；只有在启动调试端口或运行在特定隔离实例下才能工作。
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
