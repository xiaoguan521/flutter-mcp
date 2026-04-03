import Database from "better-sqlite3";

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

type PageRow = {
  slug: string;
  title: string;
  description: string | null;
  version: string;
  author: string;
  note: string | null;
  stable: number;
  created_at: string;
  updated_at: string;
  definition_json: string;
};

export class SqlitePageStore extends BasePageStore {
  private readonly database: Database.Database;

  constructor(private readonly sqlitePath: string) {
    super();
    this.database = new Database(sqlitePath);
  }

  async initialize(): Promise<void> {
    this.database.exec(`
      CREATE TABLE IF NOT EXISTS page_versions (
        slug TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        version TEXT NOT NULL,
        author TEXT NOT NULL,
        note TEXT,
        stable INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        definition_json TEXT NOT NULL,
        PRIMARY KEY (slug, version)
      );

      CREATE INDEX IF NOT EXISTS idx_page_versions_slug_created_at
        ON page_versions (slug, created_at DESC);

      CREATE INDEX IF NOT EXISTS idx_page_versions_stable
        ON page_versions (slug, stable);
    `);
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
    const rows = this.database
      .prepare(
        `
          SELECT slug, title, description, version, updated_at
          FROM page_versions
          WHERE stable = 1
          ORDER BY slug ASC
        `,
      )
      .all() as Array<{
      slug: string;
      title: string;
      description: string | null;
      version: string;
      updated_at: string;
    }>;

    return rows.map((row) => ({
      slug: row.slug,
      title: row.title,
      description: row.description ?? undefined,
      stableVersion: row.version,
      updatedAt: row.updated_at,
      stableUri: buildStableUri(row.slug),
      versionUri: buildVersionUri(row.slug, row.version),
    }));
  }

  async listVersions(slug: string): Promise<PageVersionSummary[]> {
    const normalizedSlug = normalizeSlug(slug);
    const rows = this.database
      .prepare(
        `
          SELECT slug, title, version, author, note, stable, created_at
          FROM page_versions
          WHERE slug = ?
          ORDER BY created_at DESC
        `,
      )
      .all(normalizedSlug) as Array<{
      slug: string;
      title: string;
      version: string;
      author: string;
      note: string | null;
      stable: number;
      created_at: string;
    }>;

    return rows.map((row) => ({
      slug: row.slug,
      title: row.title,
      version: row.version,
      createdAt: row.created_at,
      isStable: row.stable === 1,
      note: row.note ?? undefined,
      author: row.author,
      stableUri: buildStableUri(row.slug),
      versionUri: buildVersionUri(row.slug, row.version),
    }));
  }

  async getPage(slug: string, version?: string): Promise<PageSnapshot | null> {
    const normalizedSlug = normalizeSlug(slug);
    const row = version
      ? ((this.database
          .prepare(
            `
              SELECT *
              FROM page_versions
              WHERE slug = ? AND version = ?
              LIMIT 1
            `,
          )
          .get(normalizedSlug, version) as PageRow | undefined) ?? null)
      : ((this.database
          .prepare(
            `
              SELECT *
              FROM page_versions
              WHERE slug = ? AND stable = 1
              ORDER BY created_at DESC
              LIMIT 1
            `,
          )
          .get(normalizedSlug) as PageRow | undefined) ?? null);

    return row ? this.toSnapshot(row) : null;
  }

  async savePage(input: SavePageInput): Promise<SavePageResult> {
    const slug = normalizeSlug(input.slug);
    const version = buildVersionId();
    const now = new Date().toISOString();
    const makeStable = input.makeStable ?? true;

    const transaction = this.database.transaction(() => {
      if (makeStable) {
        this.database
          .prepare(`UPDATE page_versions SET stable = 0 WHERE slug = ?`)
          .run(slug);
      }

      this.database
        .prepare(
          `
            INSERT INTO page_versions (
              slug, title, description, version, author, note, stable,
              created_at, updated_at, definition_json
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          `,
        )
        .run(
          slug,
          input.title,
          input.description ?? null,
          version,
          input.author ?? "studio",
          input.note ?? null,
          makeStable ? 1 : 0,
          now,
          now,
          JSON.stringify(input.definition),
        );
    });

    transaction();

    const snapshot = await this.getPage(slug, version);
    if (!snapshot) {
      throw new Error(`Failed to load saved page snapshot for ${slug}@${version}`);
    }

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
    this.database.close();
  }

  private toSnapshot(row: PageRow): PageSnapshot {
    const slug = normalizeSlug(row.slug);
    return {
      slug,
      title: row.title,
      description: row.description ?? undefined,
      version: row.version,
      author: row.author,
      note: row.note ?? undefined,
      isStable: row.stable === 1,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      stableUri: buildStableUri(slug),
      versionUri: buildVersionUri(slug, row.version),
      definition: JSON.parse(row.definition_json) as PageSnapshot["definition"],
    };
  }
}

