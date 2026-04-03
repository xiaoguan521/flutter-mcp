import type { Express, Request, Response } from "express";
import { createMcpExpressApp } from "@modelcontextprotocol/sdk/server/express.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";

import { createMcpUiServer } from "./mcp-server.js";
import { ToolService } from "./tool-service.js";
import type { AppConfig, PageStore, SeedPage } from "./types.js";

function jsonError(res: Response, status: number, message: string) {
  return res.status(status).json({
    success: false,
    error: message,
  });
}

export function createHttpServer(options: {
  config: AppConfig;
  store: PageStore;
  toolService: ToolService;
  seedPages: SeedPage[];
}): Express {
  const app = createMcpExpressApp({
    host: options.config.host,
  });

  app.get("/health", (_req, res) => {
    res.json({
      success: true,
      status: "ok",
      transportMode: options.config.transportMode,
      pageStore: options.config.pageStore,
    });
  });

  app.get("/api/templates", (_req, res) => {
    res.json({
      success: true,
      result: options.seedPages.map((page) => ({
        slug: page.slug,
        title: page.title,
        description: page.description,
      })),
    });
  });

  app.get("/api/pages", async (_req, res) => {
    const pages = await options.toolService.listPages();
    res.json({
      success: true,
      result: pages,
    });
  });

  app.get("/api/pages/:slug/versions", async (req, res) => {
    const versions = await options.toolService.listVersions({
      slug: req.params.slug,
    });
    res.json({
      success: true,
      result: versions,
    });
  });

  app.get("/api/pages/:slug", async (req, res) => {
    const page = await options.toolService.loadPage({
      slug: req.params.slug,
      version:
        typeof req.query.version === "string" ? req.query.version : undefined,
    });

    if (!page) {
      return jsonError(res, 404, `Page not found: ${req.params.slug}`);
    }

    return res.json({
      success: true,
      result: page,
    });
  });

  app.post("/api/pages/:slug/save", async (req, res) => {
    const body = req.body as Record<string, unknown>;
    if (!body || typeof body !== "object") {
      return jsonError(res, 400, "JSON body is required.");
    }

    const definition = body.definition;
    if (!definition || typeof definition !== "object") {
      return jsonError(res, 400, "definition must be a JSON object.");
    }

    const title =
      typeof body.title === "string" && body.title.trim().length > 0
        ? body.title
        : req.params.slug;

    const result = await options.toolService.savePage({
      slug: req.params.slug,
      title,
      description:
        typeof body.description === "string" ? body.description : undefined,
      author: typeof body.author === "string" ? body.author : undefined,
      note: typeof body.note === "string" ? body.note : undefined,
      makeStable:
        typeof body.makeStable === "boolean" ? body.makeStable : undefined,
      definition: definition as Record<string, unknown>,
    });

    return res.status(201).json({
      success: true,
      result,
    });
  });

  app.get("/api/resources/resolve", async (req, res) => {
    const uri = typeof req.query.uri === "string" ? req.query.uri : undefined;
    if (!uri) {
      return jsonError(res, 400, "uri query parameter is required.");
    }

    const result = await options.toolService.resolveResource({ uri });
    if (!result) {
      return jsonError(res, 404, `Resource not found: ${uri}`);
    }

    return res.json({
      success: true,
      result,
    });
  });

  app.post("/api/tools/:toolName", async (req, res) => {
    const toolName = req.params.toolName;
    const payload = (req.body ?? {}) as Record<string, unknown>;

    try {
      switch (toolName) {
        case "list_pages": {
          return res.json({
            success: true,
            result: await options.toolService.listPages(),
          });
        }
        case "load_page": {
          const result = await options.toolService.loadPage({
            slug: String(payload.slug ?? ""),
            version:
              typeof payload.version === "string" ? payload.version : undefined,
          });
          if (!result) {
            return jsonError(res, 404, `Page not found: ${String(payload.slug)}`);
          }

          return res.json({
            success: true,
            result,
          });
        }
        case "save_page_version": {
          if (
            !payload.definition ||
            typeof payload.definition !== "object" ||
            typeof payload.slug !== "string" ||
            typeof payload.title !== "string"
          ) {
            return jsonError(
              res,
              400,
              "save_page_version requires slug, title, and definition.",
            );
          }

          const result = await options.toolService.savePage({
            slug: payload.slug,
            title: payload.title,
            description:
              typeof payload.description === "string"
                ? payload.description
                : undefined,
            author:
              typeof payload.author === "string" ? payload.author : undefined,
            note: typeof payload.note === "string" ? payload.note : undefined,
            makeStable:
              typeof payload.makeStable === "boolean"
                ? payload.makeStable
                : undefined,
            definition: payload.definition as Record<string, unknown>,
          });

          return res.json({
            success: true,
            result,
          });
        }
        case "generate_page": {
          const result = await options.toolService.generatePage({
            template: String(payload.template ?? ""),
            slug: typeof payload.slug === "string" ? payload.slug : undefined,
            title:
              typeof payload.title === "string" ? payload.title : undefined,
          });

          return res.json({
            success: true,
            result,
          });
        }
        case "generate_page_from_prompt": {
          if (typeof payload.prompt !== "string" || payload.prompt.trim().length === 0) {
            return jsonError(res, 400, "generate_page_from_prompt requires prompt.");
          }

          const result = await options.toolService.generatePageFromPrompt({
            prompt: payload.prompt,
            pageType:
              typeof payload.pageType === "string" ? payload.pageType : undefined,
            constraints:
              payload.constraints && typeof payload.constraints === "object"
                ? (payload.constraints as Record<string, unknown>)
                : undefined,
            seedTemplate:
              typeof payload.seedTemplate === "string"
                ? payload.seedTemplate
                : undefined,
            locale: typeof payload.locale === "string" ? payload.locale : undefined,
            slug: typeof payload.slug === "string" ? payload.slug : undefined,
            title: typeof payload.title === "string" ? payload.title : undefined,
          });

          return res.json({
            success: true,
            result,
          });
        }
        case "validate_page": {
          if (!payload.definition || typeof payload.definition !== "object") {
            return jsonError(res, 400, "validate_page requires definition.");
          }

          const result = await options.toolService.validatePage({
            definition: payload.definition as Record<string, unknown>,
          });

          return res.json({
            success: true,
            result,
          });
        }
        case "update_page_by_instruction": {
          if (!payload.definition || typeof payload.definition !== "object") {
            return jsonError(res, 400, "update_page_by_instruction requires definition.");
          }
          if (typeof payload.instruction !== "string" || payload.instruction.trim().length === 0) {
            return jsonError(
              res,
              400,
              "update_page_by_instruction requires instruction.",
            );
          }

          const result = await options.toolService.updatePageByInstruction({
            definition: payload.definition as Record<string, unknown>,
            instruction: payload.instruction,
            locale: typeof payload.locale === "string" ? payload.locale : undefined,
          });

          return res.json({
            success: true,
            result,
          });
        }
        case "list_components": {
          const result = await options.toolService.listComponents({
            category:
              typeof payload.category === "string" ? payload.category : undefined,
            recommendedOnly:
              typeof payload.recommendedOnly === "boolean"
                ? payload.recommendedOnly
                : undefined,
          });

          return res.json({
            success: true,
            result,
          });
        }
        case "resolve_resource_uri": {
          if (typeof payload.uri !== "string") {
            return jsonError(res, 400, "resolve_resource_uri requires uri.");
          }

          const result = await options.toolService.resolveResource({
            uri: payload.uri,
          });
          if (!result) {
            return jsonError(res, 404, `Resource not found: ${payload.uri}`);
          }

          return res.json({
            success: true,
            result,
          });
        }
        default:
          return jsonError(res, 404, `Unknown tool: ${toolName}`);
      }
    } catch (error) {
      return jsonError(
        res,
        500,
        error instanceof Error ? error.message : String(error),
      );
    }
  });

  app.post(options.config.mcpEndpoint, async (req: Request, res: Response) => {
    const server = createMcpUiServer({
      toolService: options.toolService,
      store: options.store,
      seedPages: options.seedPages,
    });

    try {
      const transport = new StreamableHTTPServerTransport({
        sessionIdGenerator: undefined,
      });
      await server.connect(transport);
      await transport.handleRequest(req, res, req.body);
      res.on("close", () => {
        void transport.close();
        void server.close();
      });
    } catch (error) {
      if (!res.headersSent) {
        res.status(500).json({
          jsonrpc: "2.0",
          error: {
            code: -32603,
            message: error instanceof Error ? error.message : String(error),
          },
          id: null,
        });
      }
    }
  });

  const methodNotAllowed = (_req: Request, res: Response) => {
    res.status(405).json({
      jsonrpc: "2.0",
      error: {
        code: -32000,
        message: "Method not allowed.",
      },
      id: null,
    });
  };

  app.get(options.config.mcpEndpoint, methodNotAllowed);
  app.delete(options.config.mcpEndpoint, methodNotAllowed);

  return app;
}
