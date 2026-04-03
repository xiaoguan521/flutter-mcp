import { resolve } from "node:path";

import type { AppConfig } from "./types.js";

function readPort(value: string | undefined, fallback: number): number {
  if (!value) {
    return fallback;
  }

  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) ? parsed : fallback;
}

export function loadConfig(paths: {
  workspaceRoot: string;
  serverRoot: string;
}): AppConfig {
  return {
    host: process.env.HOST ?? "127.0.0.1",
    port: readPort(process.env.PORT, 8787),
    transportMode: process.env.TRANSPORT_MODE === "stdio" ? "stdio" : "http",
    pageStore: process.env.PAGE_STORE === "valkey" ? "valkey" : "sqlite",
    sqlitePath:
      process.env.SQLITE_PATH ??
      resolve(paths.serverRoot, "data", "mcp-ui-pages.sqlite"),
    valkeyUrl: process.env.VALKEY_URL,
    workspaceRoot: paths.workspaceRoot,
    serverRoot: paths.serverRoot,
    mcpEndpoint: process.env.MCP_ENDPOINT ?? "/mcp",
  };
}

