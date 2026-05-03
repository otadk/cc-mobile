import { createServer } from 'http';
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { spawn } from 'node-pty';
import { WebSocketServer } from 'ws';

const __dirname = dirname(fileURLToPath(import.meta.url));
const PUBLIC = join(__dirname, 'public');
const PORT = parseInt(process.env.PORT || '3000', 10);
const HOST = process.env.HOST || '127.0.0.1';

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
};

function serveStatic(res, path) {
  try {
    const data = readFileSync(path);
    const ext = path.slice(path.lastIndexOf('.'));
    res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
    res.end(data);
  } catch {
    res.writeHead(404);
    res.end('Not found');
  }
}

const server = createServer((req, res) => {
  if (req.url === '/' || req.url === '/index.html') {
    serveStatic(res, join(PUBLIC, 'index.html'));
  } else if (req.url && req.url.startsWith('/')) {
    serveStatic(res, join(PUBLIC, req.url));
  } else {
    res.writeHead(404);
    res.end('Not found');
  }
});

const wss = new WebSocketServer({ server, path: '/ws' });

wss.on('connection', (ws, req) => {
  console.log('[cc-mobile] Client connected');

  const cmd = process.env.CLAUDE_CMD || 'claude';
  const pty = spawn(cmd, [], {
    name: 'xterm-256color',
    cols: 80,
    rows: 24,
    cwd: process.env.HOME || '/root',
    env: { ...process.env, TERM: 'xterm-256color' },
  });

  pty.onData((data) => {
    if (ws.readyState === ws.OPEN) {
      ws.send(data);
    }
  });

  pty.onExit(({ exitCode }) => {
    console.log('[cc-mobile] Claude exited with code', exitCode);
    if (ws.readyState === ws.OPEN) {
      ws.send('\r\n\r\n[cc-mobile] Session ended. Refresh the page to start a new session.\r\n');
    }
  });

  ws.on('message', (raw) => {
    let msg;
    try {
      msg = JSON.parse(raw.toString());
    } catch {
      return;
    }

    if (msg.type === 'input') {
      pty.write(msg.data);
    } else if (msg.type === 'resize') {
      pty.resize(msg.cols, msg.rows);
    }
  });

  ws.on('close', () => {
    console.log('[cc-mobile] Client disconnected');
    pty.kill();
  });

  ws.on('error', () => {
    pty.kill();
  });
});

server.listen(PORT, HOST, () => {
  console.log(`[cc-mobile] Server listening on http://${HOST}:${PORT}`);
});
