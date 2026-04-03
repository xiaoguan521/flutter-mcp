import type {
  PageSnapshot,
  PageStore,
  PageSummary,
  PageVersionSummary,
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
  abstract resolveUri(uri: string): Promise<PageSnapshot | null>;
  abstract close(): Promise<void>;
}

