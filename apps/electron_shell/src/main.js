const { app, BrowserWindow, shell } = require('electron');
const fs = require('node:fs');
const path = require('node:path');

const defaultFlutterIndex = path.resolve(
  __dirname,
  '../../flutter_mcp_studio/build/web/index.html',
);

function resolveFlutterEntry() {
  if (process.env.FLUTTER_WEB_URL) {
    return process.env.FLUTTER_WEB_URL;
  }

  const candidate = process.env.FLUTTER_WEB_DIST || defaultFlutterIndex;
  if (fs.existsSync(candidate)) {
    return `file://${candidate.replace(/\\/g, '/')}`;
  }

  return null;
}

function createWindow() {
  const entry = resolveFlutterEntry();
  const window = new BrowserWindow({
    width: 1440,
    height: 960,
    minWidth: 1080,
    minHeight: 720,
    backgroundColor: '#f4f1ea',
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
    },
  });

  if (entry) {
    window.loadURL(entry);
  } else {
    window.loadURL(
      'data:text/html;charset=utf-8,' +
        encodeURIComponent(`
          <html>
            <body style="font-family:Segoe UI, sans-serif;background:#f4f1ea;padding:32px;color:#0f172a">
              <h1>Flutter MCP Studio Electron Shell</h1>
              <p>未找到 Flutter Web 构建产物。</p>
              <p>请先运行 <code>flutter build web</code>，或通过环境变量 <code>FLUTTER_WEB_URL</code> 指向 dev server。</p>
            </body>
          </html>
        `),
    );
  }

  window.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });
}

app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

