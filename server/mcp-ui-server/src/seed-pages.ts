import { readdir, readFile } from "node:fs/promises";
import { resolve } from "node:path";

import type { JsonObject, SeedPage } from "./types.js";
import { normalizeSlug } from "./uri.js";

type SeedPageFile = {
  slug?: string;
  title?: string;
  description?: string;
  definition?: JsonObject;
};

export async function loadSeedPages(workspaceRoot: string): Promise<SeedPage[]> {
  const assetDir = resolve(
    workspaceRoot,
    "apps",
    "flutter_mcp_studio",
    "assets",
    "samples",
  );

  const entries = (await readdir(assetDir)).filter((file) =>
    file.endsWith(".page.json"),
  );

  const pages: SeedPage[] = [];
  for (const entry of entries.sort()) {
    const raw = await readFile(resolve(assetDir, entry), "utf8");
    const parsed = JSON.parse(raw) as SeedPageFile;
    if (!parsed.definition || !parsed.title) {
      continue;
    }

    pages.push({
      slug: normalizeSlug(parsed.slug ?? entry.replace(".page.json", "")),
      title: parsed.title,
      description: parsed.description,
      definition: parsed.definition,
    });
  }

  return pages;
}

