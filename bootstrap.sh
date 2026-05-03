#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[cc-mobile]${NC} $1"; }
warn() { echo -e "${RED}[cc-mobile]${NC} $1"; }
info() { echo -e "${CYAN}[cc-mobile]${NC} $1"; }

log "Starting cc-mobile setup..."

# ── Termux-level dependencies ──────────────────────────────────────────

log "Updating Termux packages..."
pkg update -y && pkg upgrade -y

log "Installing proot-distro..."
pkg install -y proot-distro

# ── Install Debian if needed ───────────────────────────────────────────

if proot-distro list | grep -q debian; then
  log "Debian already installed, skipping..."
else
  log "Installing Debian (this takes a few minutes)..."
  proot-distro install debian
fi

# ── Check for API key ──────────────────────────────────────────────────

if [ -z "$ANTHROPIC_API_KEY" ]; then
  info ""
  info "  ╔══════════════════════════════════════════════╗"
  info "  ║  ANTHROPIC_API_KEY not set.                  ║"
  info "  ║                                              ║"
  info "  ║  Get one at:                                 ║"
  info "  ║  https://console.anthropic.com/keys          ║"
  info "  ║                                              ║"
  info "  ║  Then run:                                   ║"
  info "  ║  export ANTHROPIC_API_KEY=your-key-here      ║"
  info "  ╚══════════════════════════════════════════════╝"
  info ""
fi

# ── Debian internal setup ──────────────────────────────────────────────

log "Setting up Debian environment..."

proot-distro login debian -- bash -c '
set -e

# System deps
apt update && apt install -y curl ca-certificates build-essential python3 make g++ git

# Node.js 22.x
if ! command -v node &>/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt install -y nodejs
fi

# Claude Code CLI
if ! command -v claude &>/dev/null; then
  npm install -g @anthropic-ai/claude-code
fi

# Remove old install if present
rm -rf /opt/cc-mobile

# Clone repo
git clone --depth 1 https://github.com/otadk/cc-mobile.git /opt/cc-mobile
cd /opt/cc-mobile/server

# Install server deps
npm install --production
'

# ── Create claude-web management command ───────────────────────────────

log "Installing claude-web command..."

proot-distro login debian -- bash -c '
cat > /usr/local/bin/claude-web << '"'"'SCRIPT'"'"'
#!/bin/bash
PIDFILE=/tmp/cc-mobile-server.pid
LOGFILE=/tmp/cc-mobile-server.log

start() {
  if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then
    echo "[cc-mobile] Server is already running (PID $(cat $PIDFILE))"
    return 1
  fi
  echo "[cc-mobile] Starting server..."
  cd /opt/cc-mobile/server
  nohup node server.js > "$LOGFILE" 2>&1 &
  echo $! > "$PIDFILE"
  sleep 1
  if kill -0 $(cat "$PIDFILE") 2>/dev/null; then
    echo "[cc-mobile] Server started on http://localhost:3000"
  else
    echo "[cc-mobile] Failed to start. Check log: $LOGFILE"
    rm -f "$PIDFILE"
    return 1
  fi
}

stop() {
  if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE")
    if kill -0 "$PID" 2>/dev/null; then
      kill "$PID" 2>/dev/null
      rm -f "$PIDFILE"
      echo "[cc-mobile] Server stopped."
    else
      rm -f "$PIDFILE"
      echo "[cc-mobile] Stale PID file removed."
    fi
  else
    echo "[cc-mobile] Server is not running."
  fi
}

status() {
  if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then
    echo "[cc-mobile] Server running (PID $(cat $PIDFILE)) on http://localhost:3000"
  else
    echo "[cc-mobile] Server not running."
    rm -f "$PIDFILE"
  fi
}

case "${1:-}" in
  start)  start ;;
  stop)   stop ;;
  status) status ;;
  *)
    echo "Usage: claude-web {start|stop|status}"
    exit 1
    ;;
esac
SCRIPT

chmod +x /usr/local/bin/claude-web
'

# ── Done ───────────────────────────────────────────────────────────────

# Start the server immediately
proot-distro login debian -- claude-web start

echo ""
log "Setup complete!"
echo ""
cat << 'MOTD'

╔══════════════════════════════════════════════════╗
║     cc-mobile — Setup Complete!                  ║
║                                                  ║
║  Open your browser and go to:                    ║
║  → http://localhost:3000                         ║
║                                                  ║
║  Manage the server from Termux:                  ║
║  $ proot-distro login debian -- claude-web start ║
║  $ proot-distro login debian -- claude-web stop  ║
║  $ proot-distro login debian -- claude-web status║
║                                                  ║
║  Tip: Set your API key if you haven'"'"'t:          ║
║  $ export ANTHROPIC_API_KEY=your-key              ║
║                                                  ║
╚══════════════════════════════════════════════════╝
MOTD
