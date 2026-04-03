import { createClient, type RedisClientType } from "redis";

import { BasePageStore } from "./page-store.js";
import {
  buildStableUri,
  buildVersionId,
  buildVersionUri,
  normalizeSlug,
  parseResourceUri,
} from "./uri.js";
import type {
  PageSnapshot,
  PageSummary,
  PageVersionSummary,
  SavePageInput,
  SavePageResult,
  SeedPage,
} from "./types.js";

const DEFAULT_NAMESPACE = "mcp-ui";

export class ValkeyPageStore extends BasePageStore {
  private client: RedisClientType;

  constructor(
    private readonly url: string,
    private readonly namespace = DEFAULT_NAMESPACE,
  ) {
    super();
    this.client = createClient({
      url,
    });
  }

  async initialize(): Promise<void> {
    if (!this.client.isOpen) {
      await this.client.connect();
    }
  }

  async seedPages(pages: SeedPage[]): Promise<void> {
    for (const page of pages) {
      const existing = await this.getPage(page.slug);
      if (existing) {
        continue;
      }

      await this.savePage({
        slug: page.slug,
        title: page.title,
        description: page.description,
        author: "system",
        note: "Seeded sample page",
        makeStable: true,
        definition: page.definition,
      });
    }
  }

  async listPages(): Promise<PageSummary[]> {
    const slugs = await this.client.sMembers(this.key("pages:index"));
    const pages: PageSummary[] = [];

    for (const slug of slugs.sort()) {
      const stableVersion = await this.client.get(this.key(`pages:${slug}:stable`));
      if (!stableVersion) {
        continue;
      }

      const page = await this.getPage(slug, stableVersion);
      if (!page) {
        continue;
      }

      pages.push({
        slug: page.slug,
        title: page.title,
        description: page.description,
        stableVersion: page.version,
        updatedAt: page.updatedAt,
        stableUri: page.stableUri,
        versionUri: page.versionUri,
      });
    }

    return pages;
  }

  async listVersions(slug: string): Promise<PageVersionSummary[]> {
    const normalizedSlug = normalizeSlug(slug);
    const versionIds = await this.client.zRange(
      this.key(`pages:${normalizedSlug}:versions`),
      0,
      -1,
      { REV: true },
    );

    const stableVersion = await this.client.get(
      this.key(`pages:${normalizedSlug}:stable`),
    );

    const versions: PageVersionSummary[] = [];
    for (const versionId of versionIds) {
      const page = await this.getPage(normalizedSlug, versionId);
      if (!page) {
        continue;
      }

      versions.push({
        slug: page.slug,
        title: page.title,
        version: page.version,
        createdAt: page.createdAt,
        isStable: stableVersion === page.version,
        note: page.note,
        author: page.author,
        stableUri: page.stableUri,
        versionUri: page.versionUri,
      });
    }

    return versions;
  }

  async getPage(slug: string, version?: string): Promise<PageSnapshot | null> {
    const normalizedSlug = normalizeSlug(slug);
    const resolvedVersion =
      version ??
      (await this.client.get(this.key(`pages:${normalizedSlug}:stable`)));

    if (!resolvedVersion) {
      return null;
    }

    const raw = await this.client.get(
      this.key(`pages:${normalizedSlug}:version:${resolvedVersion}`),
    );

    return raw ? (JSON.parse(raw) as PageSnapshot) : null;
  }

  async savePage(input: SavePageInput): Promise<SavePageResult> {
    const slug = normalizeSlug(input.slug);
    const version = buildVersionId();
    const timestamp = Date.now();
    const snapshot: PageSnapshot = {
      slug,
      title: input.title,
      description: input.description,
      version,
      author: input.author ?? "studio",
      note: input.note,
      isStable: input.makeStable ?? true,
      createdAt: new Date(timestamp).toISOString(),
      updatedAt: new Date(timestamp).toISOString(),
      stableUri: buildStableUri(slug),
      versionUri: buildVersionUri(slug, version),
      definition: input.definition,
    };

    const multi = this.client.multi();
    multi.sAdd(this.key("pages:index"), slug);
    multi.zAdd(this.key(`pages:${slug}:versions`), {
      score: timestamp,
      value: version,
    });
    multi.set(
      this.key(`pages:${slug}:version:${version}`),
      JSON.stringify(snapshot),
    );

    if (snapshot.isStable) {
      multi.set(this.key(`pages:${slug}:stable`), version);
    }

    await multi.exec();

    return {
      page: snapshot,
      stableUri: snapshot.stableUri,
      versionUri: snapshot.versionUri,
    };
  }

  async resolveUri(uri: string): Promise<PageSnapshot | null> {
    const parsed = parseResourceUri(uri);
    if (!parsed) {
      return null;
    }

    return this.getPage(parsed.slug, parsed.version);
  }

  async close(): Promise<void> {
    if (this.client.isOpen) {
      await this.client.quit();
    }
  }

  private key(value: string): string {
    return `${this.namespace}:${value}`;
  }
}

