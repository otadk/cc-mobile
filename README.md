# cc-mobile

Run [Claude Code](https://www.anthropic.com/claude) on your Android phone. One command installs everything — Debian, Node.js, Claude Code CLI, and a browser-based terminal so you can interact with Claude from Chrome on your phone.

No computer needed after setup. No Ollama, no Python, no native runtimes required.

## Quick start

1. Install [Termux](https://f-droid.org/packages/com.termux/) from F-Droid (NOT the Play Store version)

2. Open Termux and run:

```bash
curl -fsSL https://raw.githubusercontent.com/otadk/cc-mobile/main/install.sh | bash
```

3. Set your API key:

```bash
export ANTHROPIC_API_KEY=your-key-here
```

4. Open your phone browser → `http://localhost:3000`

## How it works

```
Phone browser ──WebSocket──▶ Express + node-pty ──PTY──▶ Claude Code CLI
   (xterm.js)                    (Debian proot)              (npm global)
```

- **Termux** provides the Linux userspace on Android
- **proot-distro** runs a full Debian environment (no root needed)
- **node-pty** spawns Claude Code in a pseudo-terminal
- **WebSocket** bridges terminal I/O to the browser
- **xterm.js** renders the terminal in your mobile browser

## Requirements

- Android 7.0+ (API 24)
- [Termux](https://f-droid.org/packages/com.termux/) (F-Droid version)
- ~2 GB free storage
- Internet connection (for initial setup + Claude API)

## Managing the server

From Termux:

```bash
# Start
proot-distro login debian -- claude-web start

# Stop
proot-distro login debian -- claude-web stop

# Check status
proot-distro login debian -- claude-web status
```

The server runs on `http://localhost:3000` inside Debian.

## License

MIT © [otadk](https://github.com/otadk)
