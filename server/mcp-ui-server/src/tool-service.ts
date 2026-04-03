import { createAppSchema, validateAppSchema } from "./app-tools.js";
import type {
  AppSnapshot,
  AppSummary,
  AppVersionSummary,
  ComponentCatalogItem,
  ExplainPageInput,
  ExplainPageResult,
  CreateAppInput,
  CreateAppResult,
  GeneratePageInput,
  GeneratePageFromPromptInput,
  GeneratedPageResult,
  JsonObject,
  ListComponentsInput,
  PageStore,
  SaveAppInput,
  SaveAppResult,
  SavePageInput,
  SeedPage,
  UpdatePageByInstructionInput,
  UpdatePageByInstructionResult,
  ValidateAppResult,
  ValidatePageResult,
} from "./types.js";
import {
  explainPageDefinition,
  generatePageFromPrompt,
  listComponentCatalog,
  updatePageByInstruction,
  validatePageDefinition,
} from "./page-tools.js";
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

  async listApps(): Promise<AppSummary[]> {
    return this.store.listApps();
  }

  async loadPage(input: { slug: string; version?: string }) {
    return this.store.getPage(input.slug, input.version);
  }

  async loadApp(input: { slug: string; version?: string }): Promise<AppSnapshot | null> {
    return this.store.getApp(input.slug, input.version);
  }

  async listVersions(input: { slug: string }) {
    return this.store.listVersions(input.slug);
  }

  async listAppVersions(input: { slug: string }): Promise<AppVersionSummary[]> {
    return this.store.listAppVersions(input.slug);
  }

  async savePage(input: SavePageInput) {
    return this.store.savePage(input);
  }

  async saveApp(input: SaveAppInput): Promise<SaveAppResult> {
    const validation = validateAppSchema(input.schema);
    if (!validation.valid) {
      throw new Error(
        `Invalid app schema: ${validation.errors.map((item) => `${item.path}: ${item.message}`).join("; ")}`,
      );
    }

    return this.store.saveApp({
      ...input,
      slug: String(validation.normalizedSchema.slug ?? input.slug),
      name: String(validation.normalizedSchema.name ?? input.name),
      description:
        typeof validation.normalizedSchema.description === "string"
          ? validation.normalizedSchema.description
          : input.description,
      schema: validation.normalizedSchema,
    });
  }

  async resolveResource(input: { uri: string }) {
    return this.store.resolveUri(input.uri);
  }

  async createApp(input: CreateAppInput): Promise<CreateAppResult> {
    const pageSlugs = Array.isArray(input.pageSlugs)
      ? input.pageSlugs
      : [];
    const warnings: string[] = [];
    const pages = [];

    for (const pageSlug of pageSlugs) {
      const page = await this.store.getPage(pageSlug);
      if (!page) {
        warnings.push(`Page not found and was skipped: ${pageSlug}`);
        continue;
      }
      pages.push({
        slug: page.slug,
        title: page.title,
        pageUri: page.stableUri,
      });
    }

    const schema = createAppSchema(input, pages);
    const validation = validateAppSchema(schema);
    warnings.push(
      ...validation.warnings.map((item) => `${item.path}: ${item.message}`),
    );
    if (!validation.valid) {
      throw new Error(
        `Invalid generated app schema: ${validation.errors.map((item) => `${item.path}: ${item.message}`).join("; ")}`,
      );
    }

    const saveResult = await this.store.saveApp({
      slug: String(validation.normalizedSchema.slug),
      name: String(validation.normalizedSchema.name),
      description:
        typeof validation.normalizedSchema.description === "string"
          ? validation.normalizedSchema.description
          : input.description,
      author: input.author ?? "studio",
      note: "Created from app schema initializer",
      makeStable: true,
      schema: validation.normalizedSchema,
    });

    return {
      app: saveResult.app,
      stableUri: saveResult.stableUri,
      versionUri: saveResult.versionUri,
      warnings,
    };
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

  async generatePageFromPrompt(
    input: GeneratePageFromPromptInput,
  ): Promise<GeneratedPageResult> {
    return generatePageFromPrompt(input);
  }

  async validatePage(input: { definition: JsonObject }): Promise<ValidatePageResult> {
    return validatePageDefinition(input.definition);
  }

  async validateApp(input: { schema: JsonObject }): Promise<ValidateAppResult> {
    return validateAppSchema(input.schema);
  }

  async updatePageByInstruction(
    input: UpdatePageByInstructionInput,
  ): Promise<UpdatePageByInstructionResult> {
    return updatePageByInstruction(input);
  }

  async explainPage(
    input: ExplainPageInput,
  ): Promise<ExplainPageResult> {
    return explainPageDefinition(input.definition);
  }

  async listComponents(
    input: ListComponentsInput = {},
  ): Promise<ComponentCatalogItem[]> {
    return listComponentCatalog(input);
  }
}
