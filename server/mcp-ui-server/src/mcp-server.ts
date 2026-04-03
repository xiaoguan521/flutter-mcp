import { McpServer, ResourceTemplate } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";

import { buildStableUri, buildVersionUri } from "./uri.js";
import { ToolService } from "./tool-service.js";
import type { PageStore, PageSummary, SeedPage } from "./types.js";

function asTextBlock(value: unknown) {
  return {
    type: "text" as const,
    text: JSON.stringify(value, null, 2),
  };
}

function pageResourceFromSummary(page: PageSummary) {
  return {
    name: page.title,
    title: page.title,
    uri: page.stableUri,
    mimeType: "application/vnd.mcp-ui+json",
    description: page.description,
  };
}

export function createMcpUiServer(options: {
  toolService: ToolService;
  store: PageStore;
  seedPages: SeedPage[];
}) {
  const server = new McpServer({
    name: "flutter-mcp-ui-server",
    version: "0.1.0",
    websiteUrl: "https://modelcontextprotocol.io",
  });

  server.registerTool(
    "list_pages",
    {
      title: "List saved pages",
      description: "List stable MCP UI pages currently available to render.",
    },
    async () => {
      const pages = await options.toolService.listPages();
      return {
        content: [asTextBlock(pages)],
        structuredContent: {
          pages,
        },
      };
    },
  );

  server.registerTool(
    "load_page",
    {
      title: "Load page definition",
      description:
        "Load the stable page definition or a specific immutable version.",
      inputSchema: {
        slug: z.string().min(1),
        version: z.string().optional(),
      },
    },
    async ({ slug, version }) => {
      const page = await options.toolService.loadPage({ slug, version });
      if (!page) {
        return {
          content: [asTextBlock({ error: `Page not found: ${slug}` })],
          isError: true,
        };
      }

      return {
        content: [asTextBlock(page)],
        structuredContent: page,
      };
    },
  );

  server.registerTool(
    "save_page_version",
    {
      title: "Persist page version",
      description:
        "Save a curated UI definition as a new immutable version and refresh the stable resource URI.",
      inputSchema: {
        slug: z.string().min(1),
        title: z.string().min(1),
        description: z.string().optional(),
        author: z.string().optional(),
        note: z.string().optional(),
        makeStable: z.boolean().optional(),
        definition: z.record(z.string(), z.unknown()),
      },
    },
    async ({ slug, title, description, author, note, makeStable, definition }) => {
      const result = await options.toolService.savePage({
        slug,
        title,
        description,
        author,
        note,
        makeStable,
        definition,
      });

      return {
        content: [asTextBlock(result)],
        structuredContent: result,
      };
    },
  );

  server.registerTool(
    "generate_page",
    {
      title: "Generate sample page",
      description:
        "Return a dashboard, form, or table page template as MCP UI JSON.",
      inputSchema: {
        template: z.enum(["dashboard", "form", "table"]),
        slug: z.string().optional(),
        title: z.string().optional(),
      },
    },
    async ({ template, slug, title }) => {
      const result = await options.toolService.generatePage({
        template,
        slug,
        title,
      });

      return {
        content: [asTextBlock(result)],
        structuredContent: result,
      };
    },
  );

  server.registerTool(
    "generate_page_from_prompt",
    {
      title: "Generate page from prompt",
      description:
        "Generate a renderable page DSL draft from a natural-language request.",
      inputSchema: {
        prompt: z.string().min(1),
        pageType: z.enum(["dashboard", "form", "table-list"]).optional(),
        constraints: z.record(z.string(), z.unknown()).optional(),
        seedTemplate: z.string().optional(),
        locale: z.string().optional(),
        slug: z.string().optional(),
        title: z.string().optional(),
      },
    },
    async ({ prompt, pageType, constraints, seedTemplate, locale, slug, title }) => {
      const result = await options.toolService.generatePageFromPrompt({
        prompt,
        pageType,
        constraints,
        seedTemplate,
        locale,
        slug,
        title,
      });

      return {
        content: [asTextBlock(result)],
        structuredContent: result,
      };
    },
  );

  server.registerTool(
    "validate_page",
    {
      title: "Validate page DSL",
      description:
        "Validate a page definition against the supported Sprint 1 schema subset.",
      inputSchema: {
        definition: z.record(z.string(), z.unknown()),
      },
    },
    async ({ definition }) => {
      const result = await options.toolService.validatePage({
        definition,
      });

      return {
        content: [asTextBlock(result)],
        structuredContent: result,
      };
    },
  );

  server.registerTool(
    "update_page_by_instruction",
    {
      title: "Update page by instruction",
      description:
        "Apply a natural-language edit instruction to an existing Sprint 1 page DSL.",
      inputSchema: {
        definition: z.record(z.string(), z.unknown()),
        instruction: z.string().min(1),
        locale: z.string().optional(),
      },
    },
    async ({ definition, instruction, locale }) => {
      const result = await options.toolService.updatePageByInstruction({
        definition,
        instruction,
        locale,
      });

      return {
        content: [asTextBlock(result)],
        structuredContent: result,
      };
    },
  );

  server.registerTool(
    "list_components",
    {
      title: "List supported components",
      description:
        "Return the supported component catalog and metadata for AI or Studio.",
      inputSchema: {
        category: z.string().optional(),
        recommendedOnly: z.boolean().optional(),
      },
    },
    async ({ category, recommendedOnly }) => {
      const result = await options.toolService.listComponents({
        category,
        recommendedOnly,
      });

      return {
        content: [asTextBlock(result)],
        structuredContent: {
          components: result,
        },
      };
    },
  );

  server.registerTool(
    "resolve_resource_uri",
    {
      title: "Resolve resource URI",
      description:
        "Resolve a stable or immutable MCP UI resource URI into its JSON definition.",
      inputSchema: {
        uri: z.string().min(1),
      },
    },
    async ({ uri }) => {
      const page = await options.toolService.resolveResource({ uri });
      if (!page) {
        return {
          content: [asTextBlock({ error: `Resource not found: ${uri}` })],
          isError: true,
        };
      }

      return {
        content: [asTextBlock(page)],
        structuredContent: page,
      };
    },
  );

  server.registerResource(
    "stable-pages",
    new ResourceTemplate("mcpui://pages/{slug}/stable", {
      list: async () => {
        const pages = await options.store.listPages();
        return {
          resources: pages.map(pageResourceFromSummary),
        };
      },
      complete: {
        slug: async () => {
          const pages = await options.store.listPages();
          return pages.map((page) => page.slug);
        },
      },
    }),
    {
      title: "Stable page resource",
      description: "The current curated version of a page.",
      mimeType: "application/vnd.mcp-ui+json",
    },
    async (_uri, variables) => {
      const page = await options.store.getPage(String(variables.slug));
      if (!page) {
        throw new Error(`Stable page not found: ${String(variables.slug)}`);
      }

      return {
        contents: [
          {
            uri: buildStableUri(page.slug),
            mimeType: "application/vnd.mcp-ui+json",
            text: JSON.stringify(page, null, 2),
          },
        ],
      };
    },
  );

  server.registerResource(
    "page-versions",
    new ResourceTemplate("mcpui://pages/{slug}/versions/{version}", {
      list: async () => {
        const pages = await options.store.listPages();
        const resources = [];
        for (const page of pages) {
          const versions = await options.store.listVersions(page.slug);
          for (const version of versions) {
            resources.push({
              name: `${page.title} ${version.version}`,
              title: `${page.title} ${version.version}`,
              uri: buildVersionUri(page.slug, version.version),
              mimeType: "application/vnd.mcp-ui+json",
              description: version.note,
            });
          }
        }

        return {
          resources,
        };
      },
      complete: {
        slug: async () => {
          const pages = await options.store.listPages();
          return pages.map((page) => page.slug);
        },
      },
    }),
    {
      title: "Immutable page version resource",
      description: "A historical immutable version of a page.",
      mimeType: "application/vnd.mcp-ui+json",
    },
    async (_uri, variables) => {
      const page = await options.store.getPage(
        String(variables.slug),
        String(variables.version),
      );
      if (!page) {
        throw new Error(
          `Page version not found: ${String(variables.slug)}@${String(
            variables.version,
          )}`,
        );
      }

      return {
        contents: [
          {
            uri: buildVersionUri(page.slug, page.version),
            mimeType: "application/vnd.mcp-ui+json",
            text: JSON.stringify(page, null, 2),
          },
        ],
      };
    },
  );

  return server;
}
