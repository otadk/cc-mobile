# cc-mobile

在安卓手机上运行 [Claude Code](https://www.anthropic.com/claude)。一行命令安装所有环境 — Debian、Node.js、Claude Code CLI，以及基于浏览器的终端界面，让你在手机 Chrome 里直接使用 Claude。

安装完成后无需电脑，无需 Ollama，无需 Python 或任何原生运行时。

## 快速开始

1. 从 F-Droid 安装 [Termux](https://f-droid.org/packages/com.termux/)（不要用 Play Store 版本）

2. 打开 Termux，执行：

```bash
curl -fsSL https://raw.githubusercontent.com/otadk/cc-mobile/main/install.sh | bash
```

3. 设置 API Key：

```bash
export ANTHROPIC_API_KEY=你的key
```

4. 打开手机浏览器 → `http://localhost:3000`

## 工作原理

```
手机浏览器 ──WebSocket──▶ Express + node-pty ──PTY──▶ Claude Code CLI
 (xterm.js)                  (Debian proot)             (npm 全局安装)
```

- **Termux** 在安卓上提供 Linux 用户空间
- **proot-distro** 运行完整 Debian 环境（无需 root）
- **node-pty** 在伪终端中启动 Claude Code
- **WebSocket** 把终端输入输出桥接到浏览器
- **xterm.js** 在手机浏览器中渲染完整终端

## 环境要求

- Android 7.0+ (API 24)
- [Termux](https://f-droid.org/packages/com.termux/)（F-Droid 版本）
- 约 2 GB 可用空间
- 网络连接（首次安装 + Claude API 调用）

## 管理服务器

在 Termux 中执行：

```bash
# 启动
proot-distro login debian -- claude-web start

# 停止
proot-distro login debian -- claude-web stop

# 查看状态
proot-distro login debian -- claude-web status
```

服务器在 Debian 内部监听 `http://localhost:3000`。

## 后续计划

- 原生聊天式 UI（非终端模拟）
- 多会话管理
- Termux:Widget 桌面快捷启动
- 手机通知推送
- 文件管理器集成

## 许可证

MIT © [otadk](https://github.com/otadk)
