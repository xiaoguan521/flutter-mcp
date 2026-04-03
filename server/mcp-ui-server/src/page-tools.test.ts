import assert from "node:assert/strict";
import test from "node:test";

import {
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

test("updatePageByInstruction can rename a page and append supported sections", () => {
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
