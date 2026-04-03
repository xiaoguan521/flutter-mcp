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

export interface GeneratePageFromPromptInput {
  [key: string]: unknown;
  prompt: string;
  pageType?: string;
  constraints?: JsonObject;
  seedTemplate?: string;
  locale?: string;
  slug?: string;
  title?: string;
}

export interface GeneratedPageResult {
  [key: string]: unknown;
  slug: string;
  title: string;
  pageType: string;
  seedTemplate?: string;
  definition: JsonObject;
  summary: string;
  warnings: string[];
  usedComponents: string[];
  assumptions: string[];
}

export interface UpdatePageByInstructionInput {
  [key: string]: unknown;
  definition: JsonObject;
  instruction: string;
  locale?: string;
}

export interface UpdatePageByInstructionResult {
  [key: string]: unknown;
  title: string;
  definition: JsonObject;
  summary: string;
  warnings: string[];
  usedComponents: string[];
  assumptions: string[];
  appliedChanges: string[];
}

export interface ValidationIssue {
  [key: string]: unknown;
  path: string;
  message: string;
  suggestion?: string;
}

export interface ValidatePageResult {
  [key: string]: unknown;
  valid: boolean;
  errors: ValidationIssue[];
  warnings: ValidationIssue[];
  normalizedDefinition: JsonObject;
  usedComponents: string[];
}

export interface ListComponentsInput {
  [key: string]: unknown;
  category?: string;
  recommendedOnly?: boolean;
}

export interface ComponentPropDefinition {
  [key: string]: unknown;
  name: string;
  type: string;
  required?: boolean;
  description: string;
}

export interface ComponentCatalogItem {
  [key: string]: unknown;
  name: string;
  category: string;
  description: string;
  props: ComponentPropDefinition[];
  sample: JsonObject;
  recommendedForAi: boolean;
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
