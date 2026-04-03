import assert from "node:assert/strict";
import test from "node:test";

import {
  explainPageDefinition,
  generatePageFromPrompt,
  updatePageByInstruction,
  validatePageDefinition,
} from "./page-tools.js";

test("generatePageFromPrompt returns a renderable page for each Sprint 1 type", () => {
  const dashboard = generatePageFromPrompt({
    prompt: "销售仪表盘，展示营收和转化率",
    pageType: "dashboard",
  });
  const form = generatePageFromPrompt({
    prompt: "客户录入表单，需要负责人和预算",
    pageType: "form",
  });
  const table = generatePageFromPrompt({
    prompt: "订单列表，展示 owner 和状态",
    pageType: "table-list",
  });

  for (const page of [dashboard, form, table]) {
    assert.equal(page.definition.type, "page");
    assert.ok(page.usedComponents.includes("page"));
    assert.ok(page.summary.length > 0);
  }

  assert.equal(dashboard.pageType, "dashboard");
  assert.equal(form.pageType, "form");
  assert.equal(table.pageType, "table-list");
  assert.ok(form.usedComponents.includes("form"));
  assert.ok(table.usedComponents.includes("searchBar"));
});

test("validatePageDefinition keeps non-linear content and reports warnings cleanly", () => {
  const result = validatePageDefinition({
    type: "page",
    title: "Single section page",
    content: {
      type: "antdSection",
      title: "Overview",
      child: {
        type: "text",
        content: "hello",
      },
    },
  });

  assert.equal(result.valid, true);
  assert.equal(
    (result.normalizedDefinition.content as { type: string }).type,
    "antdSection",
  );
  assert.equal(result.warnings.length, 1);
  assert.equal(result.warnings[0]?.path, "state");
});

test("updatePageByInstruction can rename a page and upsert supported sections", () => {
  const updated = updatePageByInstruction({
    definition: {
      type: "page",
      title: "Old Title",
      content: {
        type: "linear",
        direction: "vertical",
        gap: 16,
        children: [],
      },
    },
    instruction: "把标题改成客户运营看板，并增加搜索筛选和操作按钮",
  });

  assert.equal(updated.title, "客户运营看板");
  assert.match(updated.summary, /Applied 3 AI refinement changes/);
  assert.ok(updated.appliedChanges.some((item) => item.includes("title")));
  assert.ok(updated.appliedChanges.some((item) => item.includes("filter")));
  assert.ok(updated.appliedChanges.some((item) => item.includes("toolbar")));

  const content = updated.definition.content as {
    type: string;
    children: unknown[];
  };
  assert.equal(content.type, "linear");
  assert.equal(content.children.length, 2);
  assert.ok(updated.usedComponents.includes("searchBar"));
  assert.ok(updated.usedComponents.includes("button"));
});

test("updatePageByInstruction reuses existing list filters and action toolbars", () => {
  const generated = generatePageFromPrompt({
    prompt: "客户列表页，包含搜索、状态筛选和操作按钮",
    pageType: "table-list",
  });

  const updated = updatePageByInstruction({
    definition: generated.definition,
    instruction: "把标题改成客户运营看板，并增加搜索筛选和操作按钮",
  });

  const content = updated.definition.content as {
    type: string;
    children: Array<Record<string, unknown>>;
  };
  const searchBarCount = content.children.filter((child) => {
    if (child.type === "searchBar") {
      return true;
    }
    return child.type === "antdSection"
      && typeof child.child === "object"
      && child.child !== null
      && (child.child as Record<string, unknown>).type === "searchBar";
  }).length;
  const toolbarCount = content.children.filter((child) => {
    if (child.type === "linear") {
      return true;
    }
    return child.type === "antdSection"
      && typeof child.child === "object"
      && child.child !== null
      && (child.child as Record<string, unknown>).type === "linear";
  }).filter((child) => {
    const linear = child.type === "linear"
      ? child
      : child.child as Record<string, unknown>;
    const children = Array.isArray(linear.children)
      ? linear.children
      : [];
    return children.some((item) => {
      return typeof item === "object"
        && item !== null
        && (item as Record<string, unknown>).type === "button";
    });
  }).length;

  assert.equal(content.children.length, 3);
  assert.equal(searchBarCount, 1);
  assert.equal(toolbarCount, 1);
  assert.ok(updated.appliedChanges.some((item) => item.includes("existing search")));
  assert.ok(updated.appliedChanges.some((item) => item.includes("existing action")));
});

test("validatePageDefinition accepts Sprint 1 expanded form and search components", () => {
  const result = validatePageDefinition({
    type: "page",
    title: "Expanded form page",
    state: {
      initial: {
        form: {
          name: "",
          notes: "",
        },
        filters: {
          keyword: "",
          status: "all",
        },
      },
    },
    content: {
      type: "linear",
      direction: "vertical",
      children: [
        {
          type: "form",
          title: "Request Form",
          children: [
            {
              type: "input",
              label: "Name",
              binding: "app.form.name",
            },
            {
              type: "textarea",
              label: "Notes",
              binding: "app.form.notes",
              maxLines: 4,
            },
          ],
        },
        {
          type: "searchBar",
          label: "Search",
          binding: "app.filters.keyword",
          filters: [
            {
              type: "select",
              label: "Status",
              binding: "app.filters.status",
              items: [
                { value: "all", label: "All" },
                { value: "healthy", label: "Healthy" },
              ],
            },
          ],
        },
      ],
    },
  });

  assert.equal(result.valid, true);
  assert.ok(result.usedComponents.includes("form"));
  assert.ok(result.usedComponents.includes("input"));
  assert.ok(result.usedComponents.includes("textarea"));
  assert.ok(result.usedComponents.includes("searchBar"));
});

test("explainPageDefinition summarizes structure, actions, and bindings", () => {
  const explanation = explainPageDefinition({
    type: "page",
    title: "Customer Queue",
    state: {
      initial: {
        filters: {
          keyword: "",
        },
        rows: [],
      },
    },
    content: {
      type: "linear",
      direction: "vertical",
      children: [
        {
          type: "searchBar",
          label: "Search",
          binding: "app.filters.keyword",
          searchAction: {
            type: "state",
            action: "set",
            binding: "app.statusText",
            value: "Filters applied",
          },
        },
        {
          type: "antdSection",
          title: "Actions",
          child: {
            type: "linear",
            direction: "horizontal",
            children: [
              {
                type: "button",
                label: "Save page",
                click: {
                  type: "tool",
                  tool: "persistPage",
                  params: {},
                },
              },
            ],
          },
        },
      ],
    },
  });

  assert.equal(explanation.pageType, "table-list");
  assert.ok(explanation.summary.length > 0);
  assert.ok(explanation.structure.some((line) => line.includes("searchBar")));
  assert.ok(explanation.actionSummary.some((line) => line.includes("persistPage")));
  assert.ok(explanation.actionSummary.some((line) => line.includes("app.statusText")));
  assert.ok(explanation.bindingSummary.includes("app.filters.keyword"));
  assert.ok(explanation.usedComponents.includes("button"));
});
