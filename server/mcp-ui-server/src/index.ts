import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import process from "node:process";

import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

import { loadConfig } from "./config.js";
import { createHttpServer } from "./http-server.js";
import { createMcpUiServer } from "./mcp-server.js";
import { loadSeedPages } from "./seed-pages.js";
import { createPageStore } from "./store-factory.js";
import { ToolService } from "./tool-service.js";

function log(message: string) {
  process.stderr.write(`[mcp-ui-server] ${message}\n`);
}

async function main() {
  const currentDir = dirname(fileURLToPath(import.meta.url));
  const serverRoot = resolve(currentDir, "..");
  const workspaceRoot = resolve(serverRoot, "..", "..");
  const config = loadConfig({
    workspaceRoot,
    serverRoot,
  });

  const store = createPageStore(config);
  await store.initialize();

  const seedPages = await loadSeedPages(workspaceRoot);
  await store.seedPages(seedPages);

  const toolService = new ToolService(store, seedPages);

  const shutdown = async () => {
    await store.close();
  };

  process.on("SIGINT", () => {
    void shutdown().finally(() => process.exit(0));
  });
  process.on("SIGTERM", () => {
    void shutdown().finally(() => process.exit(0));
  });

  if (config.transportMode === "stdio") {
    const server = createMcpUiServer({
      toolService,
      store,
      seedPages,
    });
    const transport = new StdioServerTransport();
    await server.connect(transport);
    log("stdio transport ready");
    return;
  }

  const app = createHttpServer({
    config,
    store,
    toolService,
    seedPages,
  });

  app.listen(config.port, config.host, () => {
    log(
      `http transport ready on http://${config.host}:${config.port}${config.mcpEndpoint}`,
    );
  });
}

main().catch((error) => {
  log(error instanceof Error ? error.stack ?? error.message : String(error));
  process.exit(1);
});

