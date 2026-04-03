import type {
  AppSnapshot,
  AppSummary,
  AppVersionSummary,
  PageSnapshot,
  PageStore,
  PageSummary,
  PageVersionSummary,
  SaveAppInput,
  SaveAppResult,
  SavePageInput,
  SavePageResult,
  SeedPage,
} from "./types.js";

export abstract class BasePageStore implements PageStore {
  abstract initialize(): Promise<void>;
  abstract seedPages(pages: SeedPage[]): Promise<void>;
  abstract listPages(): Promise<PageSummary[]>;
  abstract listVersions(slug: string): Promise<PageVersionSummary[]>;
  abstract getPage(slug: string, version?: string): Promise<PageSnapshot | null>;
  abstract savePage(input: SavePageInput): Promise<SavePageResult>;
  abstract listApps(): Promise<AppSummary[]>;
  abstract listAppVersions(slug: string): Promise<AppVersionSummary[]>;
  abstract getApp(slug: string, version?: string): Promise<AppSnapshot | null>;
  abstract saveApp(input: SaveAppInput): Promise<SaveAppResult>;
  abstract resolveUri(uri: string): Promise<PageSnapshot | AppSnapshot | null>;
  abstract close(): Promise<void>;
}
