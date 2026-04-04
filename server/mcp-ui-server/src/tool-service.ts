import { spawn } from "node:child_process";
import { resolve } from "node:path";

import { createAppSchema, generateAppBlueprint, validateAppSchema } from "./app-tools.js";
import type {
  AppSnapshot,
  AppSummary,
  AppVersionSummary,
  BuildAndroidDebugInput,
  BuildAndroidDebugResult,
  BuildWebInput,
  BuildWebResult,
  ComponentCatalogItem,
  ExplainPageInput,
  ExplainPageResult,
  CreateAppInput,
  CreateAppResult,
  GeneratedAppResult,
  GeneratePageInput,
  GenerateAppFromPromptInput,
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
  AppConfig,
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
    private readonly config?: AppConfig,
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

  async generateAppFromPrompt(
    input: GenerateAppFromPromptInput,
  ): Promise<GeneratedAppResult> {
    if (typeof input.prompt !== "string" || input.prompt.trim().length === 0) {
      throw new Error("generate_app_from_prompt requires prompt.");
    }

    const blueprint = generateAppBlueprint(input);
    const warnings: string[] = [];
    const generatedPages = [];
    const appPages = [];

    for (const pagePlan of blueprint.pages) {
      const generated = await this.generatePageFromPrompt({
        prompt: pagePlan.promptHint,
        pageType: pagePlan.pageType,
        slug: pagePlan.slug,
        title: pagePlan.title,
        locale: input.locale,
      });

      const savedPage = await this.store.savePage({
        slug: generated.slug,
        title: generated.title,
        description: generated.summary,
        author: "ai",
        note: "Generated from app prompt",
        makeStable: true,
        definition: generated.definition,
      });

      appPages.push({
        slug: savedPage.page.slug,
        title: savedPage.page.title,
        pageUri: savedPage.page.stableUri,
      });
      generatedPages.push({
        slug: savedPage.page.slug,
        title: savedPage.page.title,
        pageType: generated.pageType,
        stableUri: savedPage.page.stableUri,
        versionUri: savedPage.page.versionUri,
      });
      warnings.push(...generated.warnings);
    }

    const schema = createAppSchema(
      {
        name: blueprint.name,
        slug: blueprint.slug,
        description: blueprint.description,
        navigationStyle: blueprint.navigationStyle,
      },
      appPages,
    );
    const validation = validateAppSchema(schema);
    warnings.push(...validation.warnings.map((item) => `${item.path}: ${item.message}`));
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
          : blueprint.description,
      author: "ai",
      note: "Generated from app prompt",
      makeStable: true,
      schema: validation.normalizedSchema,
    });

    return {
      app: saveResult.app,
      stableUri: saveResult.stableUri,
      versionUri: saveResult.versionUri,
      summary: blueprint.summary,
      warnings,
      assumptions: blueprint.assumptions,
      generatedPages,
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

  async buildAndroidDebug(
    input: BuildAndroidDebugInput,
  ): Promise<BuildAndroidDebugResult> {
    if (!this.config) {
      throw new Error("Build tools are unavailable without server config.");
    }

    const app = await this.store.getApp(input.slug, input.version);
    if (!app) {
      throw new Error(`App not found: ${input.slug}`);
    }

    const startedAt = new Date().toISOString();
    const projectDir = resolve(this.config.workspaceRoot, "apps", "flutter_mcp_studio");
    const scriptPath = resolve(projectDir, "build-android-apk.ps1");
    const buildMode = typeof input.buildMode === "string" && input.buildMode.trim().length > 0
      ? input.buildMode.trim()
      : "debug";
    const targetPlatform =
      typeof input.targetPlatform === "string" && input.targetPlatform.trim().length > 0
        ? input.targetPlatform.trim()
        : "android-arm64";

    const args = [
      "-ExecutionPolicy",
      "Bypass",
      "-File",
      scriptPath,
      "-BuildMode",
      buildMode,
      "-TargetPlatform",
      targetPlatform,
    ];

    const output = await new Promise<string>((resolveOutput, rejectOutput) => {
      const child = spawn("powershell", args, {
        cwd: projectDir,
        env: process.env,
        stdio: ["ignore", "pipe", "pipe"],
      });

      let combined = "";
      child.stdout.on("data", (chunk) => {
        combined += chunk.toString();
      });
      child.stderr.on("data", (chunk) => {
        combined += chunk.toString();
      });
      child.on("error", rejectOutput);
      child.on("close", (code) => {
        if (code === 0) {
          resolveOutput(combined);
          return;
        }
        rejectOutput(new Error(combined || `Android build failed with exit code ${code ?? "unknown"}.`));
      });
    });

    const artifactPath = this.extractBuildArtifactPath(output);
    const completedAt = new Date().toISOString();
    const logSummary = output
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line.length > 0)
      .slice(-12);

    return {
      success: true,
      slug: app.slug,
      version: app.version,
      profileId: typeof input.profileId === "string" ? input.profileId : undefined,
      buildMode,
      targetPlatform,
      artifactPath,
      logSummary,
      startedAt,
      completedAt,
    };
  }

  async buildWeb(
    input: BuildWebInput,
  ): Promise<BuildWebResult> {
    if (!this.config) {
      throw new Error("Build tools are unavailable without server config.");
    }

    const app = await this.store.getApp(input.slug, input.version);
    if (!app) {
      throw new Error(`App not found: ${input.slug}`);
    }

    const startedAt = new Date().toISOString();
    const projectDir = resolve(this.config.workspaceRoot, "apps", "flutter_mcp_studio");
    const buildMode =
      typeof input.buildMode === "string" && input.buildMode.trim().length > 0
        ? input.buildMode.trim()
        : "release";

    const output = await this.runProcess(
      "powershell",
      [
        "-ExecutionPolicy",
        "Bypass",
        "-Command",
        `flutter build web --${buildMode}`,
      ],
      projectDir,
    );

    const completedAt = new Date().toISOString();
    const artifactPath = resolve(projectDir, "build", "web");
    const logSummary = output
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line.length > 0)
      .slice(-12);

    return {
      success: true,
      slug: app.slug,
      version: app.version,
      profileId: typeof input.profileId === "string" ? input.profileId : undefined,
      buildMode,
      artifactPath,
      logSummary,
      startedAt,
      completedAt,
    };
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

  private extractBuildArtifactPath(output: string): string {
    const match = output.match(/APK Path\s*:\s*(.+)/);
    if (!match) {
      throw new Error("Android build finished but APK path was not found in output.");
    }
    return match[1]!.trim();
  }

  private async runProcess(
    command: string,
    args: string[],
    cwd: string,
  ): Promise<string> {
    return await new Promise<string>((resolveOutput, rejectOutput) => {
      const child = spawn(command, args, {
        cwd,
        env: process.env,
        stdio: ["ignore", "pipe", "pipe"],
      });

      let combined = "";
      child.stdout.on("data", (chunk) => {
        combined += chunk.toString();
      });
      child.stderr.on("data", (chunk) => {
        combined += chunk.toString();
      });
      child.on("error", rejectOutput);
      child.on("close", (code) => {
        if (code === 0) {
          resolveOutput(combined);
          return;
        }
        rejectOutput(
          new Error(
            combined || `Process failed with exit code ${code ?? "unknown"}.`,
          ),
        );
      });
    });
  }
}
