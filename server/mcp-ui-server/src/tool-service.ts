import type {
  GeneratePageInput,
  JsonObject,
  PageStore,
  SavePageInput,
  SeedPage,
} from "./types.js";
import { normalizeSlug } from "./uri.js";

function cloneJson<T>(value: T): T {
  return JSON.parse(JSON.stringify(value)) as T;
}

export class ToolService {
  constructor(
    private readonly store: PageStore,
    private readonly seedPages: SeedPage[],
  ) {}

  async listPages() {
    return this.store.listPages();
  }

  async loadPage(input: { slug: string; version?: string }) {
    return this.store.getPage(input.slug, input.version);
  }

  async listVersions(input: { slug: string }) {
    return this.store.listVersions(input.slug);
  }

  async savePage(input: SavePageInput) {
    return this.store.savePage(input);
  }

  async resolveResource(input: { uri: string }) {
    return this.store.resolveUri(input.uri);
  }

  async generatePage(input: GeneratePageInput) {
    const template = this.seedPages.find((page) => page.slug === input.template);
    if (!template) {
      throw new Error(`Unknown template: ${input.template}`);
    }

    const slug = normalizeSlug(input.slug ?? template.slug);
    const title = input.title ?? template.title;
    const definition = cloneJson(template.definition) as JsonObject;
    definition.title = title;

    return {
      slug,
      title,
      description: template.description,
      definition,
    };
  }
}

