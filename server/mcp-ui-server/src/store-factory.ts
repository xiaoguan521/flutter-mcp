import type { AppConfig, PageStore } from "./types.js";
import { SqlitePageStore } from "./sqlite-page-store.js";
import { ValkeyPageStore } from "./valkey-page-store.js";

export function createPageStore(config: AppConfig): PageStore {
  if (config.pageStore === "valkey") {
    if (!config.valkeyUrl) {
      throw new Error("VALKEY_URL is required when PAGE_STORE=valkey");
    }

    return new ValkeyPageStore(config.valkeyUrl);
  }

  return new SqlitePageStore(config.sqlitePath);
}

