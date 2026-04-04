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

export interface AppSnapshot {
  [key: string]: unknown;
  appId: string;
  slug: string;
  name: string;
  description?: string;
  version: string;
  author: string;
  note?: string;
  isStable: boolean;
  createdAt: string;
  updatedAt: string;
  stableUri: string;
  versionUri: string;
  schema: JsonObject;
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

export interface AppSummary {
  [key: string]: unknown;
  slug: string;
  name: string;
  description?: string;
  stableVersion: string;
  updatedAt: string;
  stableUri: string;
  versionUri: string;
  homePage?: string;
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

export interface AppVersionSummary {
  [key: string]: unknown;
  slug: string;
  name: string;
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

export interface SaveAppInput {
  [key: string]: unknown;
  slug: string;
  name: string;
  description?: string;
  author?: string;
  note?: string;
  makeStable?: boolean;
  schema: JsonObject;
}

export interface SaveAppResult {
  [key: string]: unknown;
  app: AppSnapshot;
  stableUri: string;
  versionUri: string;
}

export interface GeneratePageInput {
  [key: string]: unknown;
  template: string;
  slug?: string;
  title?: string;
}

export interface CreateAppInput {
  [key: string]: unknown;
  name: string;
  slug?: string;
  description?: string;
  pageSlugs?: string[];
  navigationStyle?: string;
  author?: string;
}

export interface CreateAppResult {
  [key: string]: unknown;
  app: AppSnapshot;
  stableUri: string;
  versionUri: string;
  warnings: string[];
}

export interface GenerateAppFromPromptInput {
  [key: string]: unknown;
  prompt: string;
  name?: string;
  slug?: string;
  navigationStyle?: string;
  locale?: string;
}

export interface GeneratedAppPageResult {
  [key: string]: unknown;
  slug: string;
  title: string;
  pageType: string;
  stableUri: string;
  versionUri: string;
}

export interface GeneratedAppResult {
  [key: string]: unknown;
  app: AppSnapshot;
  stableUri: string;
  versionUri: string;
  summary: string;
  warnings: string[];
  assumptions: string[];
  generatedPages: GeneratedAppPageResult[];
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

export interface ExplainPageInput {
  [key: string]: unknown;
  definition: JsonObject;
}

export interface ExplainPageResult {
  [key: string]: unknown;
  summary: string;
  pageType: string;
  structure: string[];
  usedComponents: string[];
  actionSummary: string[];
  bindingSummary: string[];
  warnings: string[];
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

export interface ValidateAppResult {
  [key: string]: unknown;
  valid: boolean;
  errors: ValidationIssue[];
  warnings: ValidationIssue[];
  normalizedSchema: JsonObject;
}

export interface BuildAndroidDebugInput {
  [key: string]: unknown;
  slug: string;
  version?: string;
  profileId?: string;
  targetPlatform?: string;
  buildMode?: string;
}

export interface BuildAndroidDebugResult {
  [key: string]: unknown;
  success: boolean;
  slug: string;
  version?: string;
  profileId?: string;
  buildMode: string;
  targetPlatform: string;
  artifactPath: string;
  logSummary: string[];
  startedAt: string;
  completedAt: string;
}

export interface BuildWebInput {
  [key: string]: unknown;
  slug: string;
  version?: string;
  profileId?: string;
  buildMode?: string;
}

export interface BuildWebResult {
  [key: string]: unknown;
  success: boolean;
  slug: string;
  version?: string;
  profileId?: string;
  buildMode: string;
  artifactPath: string;
  logSummary: string[];
  startedAt: string;
  completedAt: string;
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

export type ResourceSnapshot = PageSnapshot | AppSnapshot;

export interface PageStore {
  initialize(): Promise<void>;
  seedPages(pages: SeedPage[]): Promise<void>;
  listPages(): Promise<PageSummary[]>;
  listVersions(slug: string): Promise<PageVersionSummary[]>;
  getPage(slug: string, version?: string): Promise<PageSnapshot | null>;
  savePage(input: SavePageInput): Promise<SavePageResult>;
  listApps(): Promise<AppSummary[]>;
  listAppVersions(slug: string): Promise<AppVersionSummary[]>;
  getApp(slug: string, version?: string): Promise<AppSnapshot | null>;
  saveApp(input: SaveAppInput): Promise<SaveAppResult>;
  resolveUri(uri: string): Promise<ResourceSnapshot | null>;
  close(): Promise<void>;
}
