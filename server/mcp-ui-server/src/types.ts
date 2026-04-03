export type JsonPrimitive = string | number | boolean | null;

export type JsonValue =
  | JsonPrimitive
  | JsonValue[]
  | {
      [key: string]: JsonValue;
    };

export type JsonObject = Record<string, unknown>;

export interface SeedPage {
  [key: string]: unknown;
  slug: string;
  title: string;
  description?: string;
  definition: JsonObject;
}

export interface PageSnapshot {
  [key: string]: unknown;
  slug: string;
  title: string;
  description?: string;
  version: string;
  author: string;
  note?: string;
  isStable: boolean;
  createdAt: string;
  updatedAt: string;
  stableUri: string;
  versionUri: string;
  definition: JsonObject;
}

export interface PageSummary {
  [key: string]: unknown;
  slug: string;
  title: string;
  description?: string;
  stableVersion: string;
  updatedAt: string;
  stableUri: string;
  versionUri: string;
}

export interface PageVersionSummary {
  [key: string]: unknown;
  slug: string;
  title: string;
  version: string;
  createdAt: string;
  isStable: boolean;
  note?: string;
  author: string;
  stableUri: string;
  versionUri: string;
}

export interface SavePageInput {
  [key: string]: unknown;
  slug: string;
  title: string;
  description?: string;
  author?: string;
  note?: string;
  makeStable?: boolean;
  definition: JsonObject;
}

export interface SavePageResult {
  [key: string]: unknown;
  page: PageSnapshot;
  stableUri: string;
  versionUri: string;
}

export interface GeneratePageInput {
  [key: string]: unknown;
  template: string;
  slug?: string;
  title?: string;
}

export interface AppConfig {
  host: string;
  port: number;
  transportMode: "http" | "stdio";
  pageStore: "sqlite" | "valkey";
  sqlitePath: string;
  valkeyUrl?: string;
  workspaceRoot: string;
  serverRoot: string;
  mcpEndpoint: string;
}

export interface PageStore {
  initialize(): Promise<void>;
  seedPages(pages: SeedPage[]): Promise<void>;
  listPages(): Promise<PageSummary[]>;
  listVersions(slug: string): Promise<PageVersionSummary[]>;
  getPage(slug: string, version?: string): Promise<PageSnapshot | null>;
  savePage(input: SavePageInput): Promise<SavePageResult>;
  resolveUri(uri: string): Promise<PageSnapshot | null>;
  close(): Promise<void>;
}
