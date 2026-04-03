import assert from "node:assert/strict";
import test from "node:test";

import { createAppSchema, validateAppSchema } from "./app-tools.js";

test("createAppSchema builds routes and navigation from page references", () => {
  const schema = createAppSchema(
    {
      name: "Operations Console",
      description: "Backoffice app for ops workflows",
      pageSlugs: ["dashboard", "orders"],
    },
    [
      {
        slug: "dashboard",
        title: "Dashboard",
        pageUri: "mcpui://pages/dashboard/stable",
      },
      {
        slug: "orders",
        title: "Orders",
        pageUri: "mcpui://pages/orders/stable",
      },
    ],
  );

  assert.equal(schema.type, "app");
  assert.equal(schema.slug, "operations-console");
  assert.equal(schema.homePage, "dashboard");
  assert.equal((schema.pages as unknown[]).length, 2);
  assert.equal((schema.routes as Array<{ path: string }>)[0]?.path, "/");
  assert.equal((schema.routes as Array<{ path: string }>)[1]?.path, "/orders");
  assert.equal((schema.navigation as Array<{ route: string }>)[1]?.route, "/orders");
});

test("validateAppSchema normalizes missing app fields and reports issues", () => {
  const result = validateAppSchema({
    name: "My Console",
    routes: [
      {
        path: "orders",
        pageSlug: "orders",
      },
    ],
  });

  assert.equal(result.valid, false);
  assert.equal(result.normalizedSchema.type, "app");
  assert.equal(result.normalizedSchema.slug, "my-console");
  assert.ok(result.warnings.some((item) => item.path === "pages"));
  assert.ok(result.errors.some((item) => item.path === "routes[0].path"));
});
