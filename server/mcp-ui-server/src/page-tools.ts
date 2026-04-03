import { randomUUID } from "node:crypto";
import type {
  ComponentCatalogItem,
  GeneratePageFromPromptInput,
  GeneratedPageResult,
  JsonObject,
  ListComponentsInput,
  UpdatePageByInstructionInput,
  UpdatePageByInstructionResult,
  ValidatePageResult,
  ValidationIssue,
} from "./types.js";
import { normalizeSlug } from "./uri.js";

type PageType = "dashboard" | "form" | "table-list";
type Scenario =
  | "sales"
  | "customer"
  | "orders"
  | "service"
  | "approval"
  | "inventory";

type ValidationContext = {
  errors: ValidationIssue[];
  warnings: ValidationIssue[];
  usedComponents: Set<string>;
};

function cloneJson<T>(value: T): T {
  return JSON.parse(JSON.stringify(value)) as T;
}

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function truncateText(value: string, maxLength: number): string {
  const trimmed = value.trim();
  if (trimmed.length <= maxLength) {
    return trimmed;
  }

  return `${trimmed.slice(0, Math.max(0, maxLength - 3))}...`;
}

function promptSnippet(prompt: string): string {
  return truncateText(prompt.replace(/\s+/g, " "), 48);
}

function toPageType(value?: string): PageType | null {
  switch (value) {
    case "dashboard":
      return "dashboard";
    case "form":
      return "form";
    case "table":
    case "table-list":
      return "table-list";
    default:
      return null;
  }
}

function inferPageType(input: GeneratePageFromPromptInput): PageType {
  const explicit = toPageType(input.pageType) ?? toPageType(input.seedTemplate);
  if (explicit) {
    return explicit;
  }

  const prompt = input.prompt.toLowerCase();
  if (
    /form|input|submit|approval|apply|request|field/.test(prompt) ||
    /表单|录入|审批|申请|字段/.test(input.prompt)
  ) {
    return "form";
  }

  if (
    /table|list|orders|rows|grid|queue/.test(prompt) ||
    /表格|列表|清单|订单/.test(input.prompt)
  ) {
    return "table-list";
  }

  return "dashboard";
}

function inferScenario(prompt: string, pageType: PageType): Scenario {
  const lowercase = prompt.toLowerCase();
  if (/sales|revenue|pipeline|quota/.test(lowercase) || /销售|营收|业绩|签约/.test(prompt)) {
    return "sales";
  }
  if (/customer|crm|lead|contact/.test(lowercase) || /客户|线索|联系人/.test(prompt)) {
    return "customer";
  }
  if (/inventory|stock|warehouse|sku/.test(lowercase) || /库存|仓|sku/.test(prompt)) {
    return "inventory";
  }
  if (/service|latency|incident|slo|alert/.test(lowercase) || /服务|告警|监控|延迟/.test(prompt)) {
    return "service";
  }
  if (/approval|workflow|request|apply/.test(lowercase) || /审批|流程|申请/.test(prompt)) {
    return "approval";
  }
  if (/order|fulfillment|shipment/.test(lowercase) || /订单|履约|发货/.test(prompt)) {
    return "orders";
  }
  return pageType === "form" ? "approval" : pageType === "table-list" ? "orders" : "sales";
}

function buildTitle(prompt: string, pageType: PageType): string {
  const snippet = truncateText(prompt, 18);
  if (pageType === "form") {
    return snippet ? `${snippet} Form` : "AI Generated Form";
  }
  if (pageType === "table-list") {
    return snippet ? `${snippet} List` : "AI Generated List";
  }
  return snippet ? `${snippet} Dashboard` : "AI Generated Dashboard";
}

function generatedSlugBase(prompt: string, title: string, pageType: PageType): string {
  const candidates = [normalizeSlug(prompt), normalizeSlug(title)];
  for (const candidate of candidates) {
    if (candidate) {
      return candidate.slice(0, 40).replace(/^-+|-+$/g, "") || candidate;
    }
  }

  return pageType === "table-list" ? "table" : pageType;
}

function resolveSlug(
  inputSlug: string | undefined,
  prompt: string,
  title: string,
  pageType: PageType,
): string {
  const explicitSlug = normalizeSlug(inputSlug ?? "");
  if (explicitSlug) {
    return explicitSlug;
  }

  const slugBase = generatedSlugBase(prompt, title, pageType);
  return `ai-${slugBase}-${randomUUID().slice(0, 8)}`;
}

function ensureStateInitial(definition: JsonObject): JsonObject {
  const state = isObject(definition.state)
    ? definition.state
    : ((definition.state = {}) as JsonObject);
  return isObject(state.initial)
    ? state.initial
    : ((state.initial = {}) as JsonObject);
}

function ensureLinearRoot(definition: JsonObject): JsonObject {
  const content = definition.content;
  if (isObject(content) && content.type === "linear") {
    if (typeof content.direction !== "string") {
      content.direction = "vertical";
    }
    if (typeof content.gap !== "number") {
      content.gap = 16;
    }
    if (!Array.isArray(content.children)) {
      content.children = [];
    }
    return content;
  }

  definition.content = {
    type: "linear",
    direction: "vertical",
    gap: 16,
    children: isObject(content) ? [content] : [],
  };
  return definition.content as JsonObject;
}

function appendRootChild(definition: JsonObject, child: JsonObject): void {
  const root = ensureLinearRoot(definition);
  const children = root.children as unknown[];
  children.push(child);
}

type ExistingSearchBarTarget = {
  searchBar: JsonObject;
};

type ExistingToolbarTarget = {
  toolbar: JsonObject;
};

function defaultStatusFilterItems(): JsonObject[] {
  return [
    { value: "all", label: "All" },
    { value: "healthy", label: "Healthy" },
    { value: "watch", label: "Watch" },
    { value: "degraded", label: "Degraded" },
  ];
}

function rootChildren(definition: JsonObject): JsonObject[] {
  const root = ensureLinearRoot(definition);
  const children = root.children as unknown[];
  return children.filter(isObject);
}

function linearHasButtons(node: JsonObject): boolean {
  return Array.isArray(node.children)
    && node.children.some((child) => isObject(child) && child.type === "button");
}

function findExistingSearchBar(definition: JsonObject): ExistingSearchBarTarget | null {
  for (const child of rootChildren(definition)) {
    if (child.type === "searchBar") {
      return { searchBar: child };
    }

    if (
      child.type === "antdSection"
      && isObject(child.child)
      && child.child.type === "searchBar"
    ) {
      return { searchBar: child.child };
    }
  }

  return null;
}

function findExistingToolbar(definition: JsonObject): ExistingToolbarTarget | null {
  for (const child of rootChildren(definition)) {
    if (child.type === "linear" && linearHasButtons(child)) {
      return { toolbar: child };
    }

    if (
      child.type === "antdSection"
      && isObject(child.child)
      && child.child.type === "linear"
      && linearHasButtons(child.child)
    ) {
      return { toolbar: child.child };
    }
  }

  return null;
}

function ensureSearchBarDefinition(searchBar: JsonObject): void {
  searchBar.type = "searchBar";
  if (typeof searchBar.label !== "string" || searchBar.label.trim().length === 0) {
    searchBar.label = "Search";
  }
  if (typeof searchBar.binding !== "string" || searchBar.binding.trim().length === 0) {
    searchBar.binding = "app.filters.keyword";
  }
  if (typeof searchBar.placeholder !== "string" || searchBar.placeholder.trim().length === 0) {
    searchBar.placeholder = "Enter keyword";
  }
  if (typeof searchBar.buttonLabel !== "string" || searchBar.buttonLabel.trim().length === 0) {
    searchBar.buttonLabel = "Apply Filters";
  }
  if (!isObject(searchBar.searchAction)) {
    searchBar.searchAction = stateAction("app.statusText", "set", "Filters updated");
  }

  const filters = Array.isArray(searchBar.filters)
    ? searchBar.filters
    : ((searchBar.filters = []) as unknown[]);
  const existingStatusFilter = filters.find((filter) => {
    return isObject(filter)
      && filter.type === "select"
      && filter.binding === "app.filters.status";
  });

  if (!existingStatusFilter) {
    filters.push({
      type: "select",
      label: "Status",
      binding: "app.filters.status",
      items: defaultStatusFilterItems(),
    });
    return;
  }

  if (
    typeof existingStatusFilter.label !== "string"
    || existingStatusFilter.label.trim().length === 0
  ) {
    existingStatusFilter.label = "Status";
  }
  if (!Array.isArray(existingStatusFilter.items) || existingStatusFilter.items.length === 0) {
    existingStatusFilter.items = defaultStatusFilterItems();
  }
}

function isPersistButton(button: JsonObject): boolean {
  return isObject(button.click)
    && button.click.type === "tool"
    && button.click.tool === "persistPage";
}

function isStatusButton(button: JsonObject): boolean {
  return isObject(button.click)
    && button.click.type === "state"
    && button.click.binding === "app.statusText";
}

function ensureToolbarDefinition(toolbar: JsonObject): void {
  toolbar.type = "linear";
  if (typeof toolbar.direction !== "string") {
    toolbar.direction = "horizontal";
  }
  if (typeof toolbar.gap !== "number") {
    toolbar.gap = 12;
  }
  if (typeof toolbar.wrap !== "boolean") {
    toolbar.wrap = true;
  }

  const children = Array.isArray(toolbar.children)
    ? toolbar.children
    : ((toolbar.children = []) as unknown[]);
  const buttons = children.filter((child): child is JsonObject => {
    return isObject(child) && child.type === "button";
  });

  if (!buttons.some(isStatusButton)) {
    children.unshift({
      type: "button",
      label: "Mark Ready",
      variant: "outlined",
      click: stateAction("app.statusText", "set", "Ready after AI update"),
    });
  }

  if (!buttons.some(isPersistButton)) {
    children.push({
      type: "button",
      label: "Save Page",
      variant: "filled",
      backgroundColor: "#0f766e",
      click: persistAction(),
    });
  }
}

function upsertSearchSection(definition: JsonObject): "added" | "updated" {
  const existing = findExistingSearchBar(definition);
  if (existing != null) {
    ensureSearchBarDefinition(existing.searchBar);
    return "updated";
  }

  appendRootChild(definition, buildFilterSection("Query Filters"));
  return "added";
}

function upsertToolbarSection(definition: JsonObject): "added" | "updated" {
  const existing = findExistingToolbar(definition);
  if (existing != null) {
    ensureToolbarDefinition(existing.toolbar);
    return "updated";
  }

  appendRootChild(definition, buildToolbarSection("Action Bar"));
  return "added";
}

function extractRequestedTitle(instruction: string): string | null {
  const patterns = [
    /(?:页面标题|标题)\s*(?:改成|改为|设为|叫做)\s*[“"]?([^"”，,\n。；;]+)[”"]?/i,
    /(?:rename\s+(?:the\s+)?)?title\s*(?:to|as|:)\s*[“"]?([^"”,\n.;]+)[”"]?/i,
  ];

  for (const pattern of patterns) {
    const match = instruction.match(pattern);
    const title = match?.[1]?.trim();
    if (title) {
      return title;
    }
  }

  if (/(?:标题|title)/i.test(instruction)) {
    const quoted = instruction.match(/[“"]([^"”]{2,48})[”"]/);
    if (quoted?.[1]) {
      return quoted[1].trim();
    }
  }

  return null;
}

function buildKpiSection(title: string): JsonObject {
  return {
    type: "antdSection",
    title,
    subtitle: "Added from AI refinement instruction.",
    child: {
      type: "linear",
      direction: "horizontal",
      gap: 12,
      wrap: true,
      children: [
        { type: "antdStat", title: "Completion", value: "84", suffix: "%", trend: "+6%", tone: "teal" },
        { type: "antdStat", title: "Backlog", value: "18", trend: "-3", tone: "amber" },
        { type: "antdStat", title: "Owner Coverage", value: "12", trend: "Stable", tone: "blue" },
      ],
    },
  };
}

function buildFilterSection(title: string): JsonObject {
  return {
    type: "antdSection",
    title,
    subtitle: "Search and filter controls generated from the refinement request.",
    child: {
      type: "searchBar",
      label: "Search",
      binding: "app.filters.keyword",
      placeholder: "Enter keyword",
      buttonLabel: "Apply Filters",
      searchAction: stateAction("app.statusText", "set", "Filters updated"),
      filters: [
        {
          type: "select",
          label: "Status",
          binding: "app.filters.status",
          items: defaultStatusFilterItems(),
        },
      ],
    },
  };
}

function buildTableSection(title: string): JsonObject {
  return {
    type: "antdSection",
    title,
    subtitle: "Generated table block from the refinement request.",
    child: {
      type: "antdTable",
      columns: [
        { key: "name", title: "Name" },
        { key: "owner", title: "Owner" },
        { key: "status", title: "Status" },
      ],
      rows: [
        { name: "Pending review", owner: "Ops", status: "watch" },
        { name: "Ready to publish", owner: "Studio", status: "healthy" },
        { name: "Needs follow-up", owner: "Product", status: "degraded" },
      ],
    },
  };
}

function buildFormSection(title: string): JsonObject {
  return {
    type: "form",
    title,
    subtitle: "Generated form fields from the refinement instruction.",
    children: [
      {
        type: "input",
        label: "Request Name",
        binding: "app.form.requestName",
        placeholder: "Enter request name",
      },
      {
        type: "select",
        label: "Priority",
        binding: "app.form.priority",
        items: [
          { value: "low", label: "Low" },
          { value: "medium", label: "Medium" },
          { value: "high", label: "High" },
        ],
      },
      {
        type: "numberField",
        label: "Budget",
        value: { binding: "app.form.budget" },
        prefix: "$ ",
        step: 1000,
        change: stateAction("app.form.budget", "set", "{{event.value}}"),
      },
      {
        type: "textarea",
        label: "Notes",
        binding: "app.form.notes",
        placeholder: "Enter supporting notes",
        maxLines: 4,
      },
    ],
  };
}

function normalizeFormField(field: JsonObject): JsonObject {
  if (field.type !== "textInput") {
    return field;
  }

  return {
    ...field,
    type: typeof field.maxLines === "number" && field.maxLines > 1
      ? "textarea"
      : "input",
  };
}

function buildToolbarSection(title: string): JsonObject {
  return {
    type: "antdSection",
    title,
    subtitle: "Action shortcuts added during AI refinement.",
    child: {
      type: "linear",
      direction: "horizontal",
      gap: 12,
      wrap: true,
      children: [
        {
          type: "button",
          label: "Mark Ready",
          variant: "outlined",
          click: stateAction("app.statusText", "set", "Ready after AI update"),
        },
        {
          type: "button",
          label: "Save Page",
          variant: "filled",
          backgroundColor: "#0f766e",
          click: persistAction(),
        },
      ],
    },
  };
}

function buildNoteSection(title: string, instruction: string): JsonObject {
  return {
    type: "antdSection",
    title,
    subtitle: "Fallback note added because the instruction needs manual follow-up.",
    child: {
      type: "text",
      content: `Follow-up requested: ${promptSnippet(instruction)}`,
    },
  };
}

function addInstructionWarnings(instruction: string, warnings: string[]): void {
  const rules = [
    {
      pattern: /分页|pagination/i,
      message: "Pagination is not modeled in Sprint 1 yet; please wire it manually later.",
    },
    {
      pattern: /图表|chart/i,
      message: "Chart components are outside the current Sprint 1 whitelist.",
    },
    {
      pattern: /详情|跳转|detail|navigate/i,
      message: "Navigation/detail flows are not auto-generated in this updater yet.",
    },
    {
      pattern: /modal|drawer|弹窗/i,
      message: "Modal and drawer components are not auto-generated in Sprint 1 updates.",
    },
  ];

  for (const rule of rules) {
    if (rule.pattern.test(instruction) && !warnings.includes(rule.message)) {
      warnings.push(rule.message);
    }
  }
}

function stateAction(binding: string, action: string, value: unknown): JsonObject {
  return {
    type: "state",
    action,
    binding,
    value,
  };
}

function persistAction(): JsonObject {
  return {
    type: "tool",
    tool: "persistPage",
    params: {},
  };
}

function dashboardPreset(
  title: string,
  prompt: string,
  scenario: Scenario,
): { definition: JsonObject; description: string } {
  const metricsByScenario: Record<Scenario, JsonObject[]> = {
    sales: [
      { type: "antdStat", title: "Revenue", value: "4.8", suffix: "M", trend: "+18%", tone: "teal" },
      { type: "antdStat", title: "Conversion", value: "31.4", suffix: "%", trend: "+2.3%", tone: "blue" },
      { type: "antdStat", title: "At Risk Deals", value: "9", trend: "-1", tone: "amber" },
      { type: "antdStat", title: "Forecast Confidence", value: "92", suffix: "%", trend: "Stable", tone: "slate" },
    ],
    customer: [
      { type: "antdStat", title: "New Leads", value: "148", trend: "+12 this week", tone: "teal" },
      { type: "antdStat", title: "Qualified", value: "63", trend: "+9", tone: "blue" },
      { type: "antdStat", title: "Dormant Accounts", value: "11", trend: "-2", tone: "amber" },
      { type: "antdStat", title: "Follow-up SLA", value: "96.2", suffix: "%", trend: "Stable", tone: "slate" },
    ],
    orders: [
      { type: "antdStat", title: "Orders Today", value: "12,480", trend: "+12%", tone: "teal" },
      { type: "antdStat", title: "Late Shipments", value: "28", trend: "-4", tone: "amber" },
      { type: "antdStat", title: "Fulfillment Rate", value: "98.7", suffix: "%", trend: "+0.3%", tone: "blue" },
      { type: "antdStat", title: "Manual Reviews", value: "14", trend: "Watch list", tone: "slate" },
    ],
    service: [
      { type: "antdStat", title: "Healthy Services", value: "19", trend: "+1", tone: "teal" },
      { type: "antdStat", title: "Open Alerts", value: "7", trend: "-3", tone: "amber" },
      { type: "antdStat", title: "P95 Latency", value: "118", suffix: "ms", trend: "-9ms", tone: "blue" },
      { type: "antdStat", title: "SLO Burn", value: "1.8", suffix: "x", trend: "Under watch", tone: "slate" },
    ],
    approval: [
      { type: "antdStat", title: "Open Requests", value: "16", trend: "+3", tone: "teal" },
      { type: "antdStat", title: "Blocked", value: "4", trend: "-1", tone: "amber" },
      { type: "antdStat", title: "Approval SLA", value: "93.5", suffix: "%", trend: "+1.2%", tone: "blue" },
      { type: "antdStat", title: "Escalations", value: "2", trend: "Stable", tone: "slate" },
    ],
    inventory: [
      { type: "antdStat", title: "Available SKUs", value: "1,284", trend: "+32", tone: "teal" },
      { type: "antdStat", title: "Low Stock", value: "46", trend: "-8", tone: "amber" },
      { type: "antdStat", title: "Turnover", value: "7.3", suffix: "x", trend: "+0.6x", tone: "blue" },
      { type: "antdStat", title: "Blocked Batches", value: "3", trend: "Needs review", tone: "slate" },
    ],
  };

  const rowsByScenario: Record<Scenario, { title: string; subtitle: string; columns: JsonObject[]; rows: JsonObject[] }> = {
    sales: { title: "Deal Focus", subtitle: "Key follow-up items derived from the prompt.", columns: [{ key: "initiative", title: "Initiative" }, { key: "owner", title: "Owner" }, { key: "status", title: "Status" }, { key: "target", title: "Target" }], rows: [{ initiative: "Enterprise pipeline", owner: "Regional Sales", status: "healthy", target: "1.4M" }, { initiative: "Partner co-sell", owner: "Channel Team", status: "watch", target: "620K" }, { initiative: "Renewal recovery", owner: "CS Team", status: "degraded", target: "280K" }] },
    customer: { title: "Pipeline Focus", subtitle: "Generated from the customer-facing prompt.", columns: [{ key: "account", title: "Account" }, { key: "owner", title: "Owner" }, { key: "stage", title: "Stage" }, { key: "nextStep", title: "Next Step" }], rows: [{ account: "Northwind Retail", owner: "Ava Chen", stage: "Proposal", nextStep: "Pricing review" }, { account: "BluePeak Health", owner: "Leo Tan", stage: "Discovery", nextStep: "Demo setup" }, { account: "Orion Foods", owner: "Mia Zhao", stage: "Negotiation", nextStep: "Legal sign-off" }] },
    orders: { title: "Fulfillment Focus", subtitle: "Recent order execution risks and owners.", columns: [{ key: "queue", title: "Queue" }, { key: "owner", title: "Owner" }, { key: "status", title: "Status" }, { key: "volume", title: "Volume" }], rows: [{ queue: "Pending shipment", owner: "Warehouse Ops", status: "watch", volume: "312" }, { queue: "Manual refund review", owner: "Finance Ops", status: "healthy", volume: "28" }, { queue: "Address exception", owner: "CX Ops", status: "degraded", volume: "17" }] },
    service: { title: "Service Watchlist", subtitle: "Use this section to track alerts and owners.", columns: [{ key: "service", title: "Service" }, { key: "owner", title: "Owner" }, { key: "status", title: "Status" }, { key: "latency", title: "P95" }], rows: [{ service: "Order API", owner: "Traffic Team", status: "healthy", latency: "92ms" }, { service: "Inventory API", owner: "Supply Team", status: "watch", latency: "164ms" }, { service: "Notification API", owner: "Platform Team", status: "degraded", latency: "228ms" }] },
    approval: { title: "Approval Queue", subtitle: "Generated queue for faster human review.", columns: [{ key: "request", title: "Request" }, { key: "owner", title: "Owner" }, { key: "status", title: "Status" }, { key: "eta", title: "ETA" }], rows: [{ request: "Campaign launch", owner: "Ops Team", status: "healthy", eta: "Today" }, { request: "Budget exception", owner: "Finance Team", status: "watch", eta: "Tomorrow" }, { request: "Vendor onboarding", owner: "Procurement", status: "degraded", eta: "Friday" }] },
    inventory: { title: "Inventory Exceptions", subtitle: "Generated stock exceptions for fast review.", columns: [{ key: "sku", title: "SKU" }, { key: "warehouse", title: "Warehouse" }, { key: "status", title: "Status" }, { key: "stock", title: "Stock" }], rows: [{ sku: "SKU-8821", warehouse: "Hangzhou", status: "watch", stock: "18" }, { sku: "SKU-1093", warehouse: "Shenzhen", status: "healthy", stock: "142" }, { sku: "SKU-5510", warehouse: "Chengdu", status: "degraded", stock: "6" }] },
  };

  const table = rowsByScenario[scenario];
  return {
    description: `AI generated dashboard draft for "${promptSnippet(prompt)}".`,
    definition: {
      type: "page",
      title,
      state: { initial: { selectedScope: "global", kpiDelta: 2, dashboardRows: table.rows } },
      content: {
        type: "linear",
        direction: "vertical",
        gap: 16,
        children: [
          { type: "antdSection", title: `${title} Overview`, subtitle: `Generated from: ${promptSnippet(prompt)}`, child: { type: "linear", direction: "horizontal", gap: 12, wrap: true, children: metricsByScenario[scenario] } },
          { type: "antdSection", title: "Controls", subtitle: "Use the generated state and tool actions as a starting point.", child: { type: "linear", direction: "horizontal", gap: 12, wrap: true, children: [{ type: "select", label: "Scope", binding: "app.selectedScope", items: [{ value: "global", label: "Global" }, { value: "region", label: "Region" }, { value: "team", label: "Team" }] }, { type: "button", label: "Refresh KPIs", variant: "outlined", click: stateAction("app.kpiDelta", "increment", 1) }, { type: "button", label: "Save draft", variant: "filled", backgroundColor: "#0f766e", click: persistAction() }] } },
          { type: "antdSection", title: table.title, subtitle: table.subtitle, child: { type: "antdTable", columns: table.columns, rows: { binding: "app.dashboardRows" } } },
        ],
      },
    },
  };
}

function formPreset(
  title: string,
  prompt: string,
  scenario: Scenario,
): { definition: JsonObject; description: string } {
  const fieldsByScenario: Record<Scenario, { state: JsonObject; fields: JsonObject[] }> = {
    sales: {
      state: { requestName: "Regional campaign", owner: "Sales Ops", priority: "high", budget: 120000, channel: "email", notes: "Coordinate sales, support, and logistics." },
      fields: [
        { type: "textInput", label: "Request Name", binding: "app.form.requestName", placeholder: "Enter request name" },
        { type: "textInput", label: "Owner", binding: "app.form.owner", placeholder: "Enter owner" },
        { type: "select", label: "Priority", binding: "app.form.priority", items: [{ value: "low", label: "Low" }, { value: "medium", label: "Medium" }, { value: "high", label: "High" }] },
        { type: "numberField", label: "Budget", value: { binding: "app.form.budget" }, prefix: "$ ", step: 1000, change: stateAction("app.form.budget", "set", "{{event.value}}") },
        { type: "select", label: "Notify Via", binding: "app.form.channel", items: [{ value: "email", label: "Email" }, { value: "wechat", label: "WeChat" }, { value: "sms", label: "SMS" }] },
        { type: "textInput", label: "Notes", binding: "app.form.notes", maxLines: 4, placeholder: "Enter supporting notes" },
      ],
    },
    customer: {
      state: { customerName: "Northwind Retail", owner: "Ava Chen", stage: "qualified", expectedValue: 320000, source: "partner", notes: "Coordinate with presales before proposal." },
      fields: [
        { type: "textInput", label: "Customer Name", binding: "app.form.customerName", placeholder: "Enter customer name" },
        { type: "textInput", label: "Account Owner", binding: "app.form.owner", placeholder: "Enter account owner" },
        { type: "select", label: "Stage", binding: "app.form.stage", items: [{ value: "new", label: "New" }, { value: "qualified", label: "Qualified" }, { value: "proposal", label: "Proposal" }] },
        { type: "numberField", label: "Expected Value", value: { binding: "app.form.expectedValue" }, prefix: "$ ", step: 1000, change: stateAction("app.form.expectedValue", "set", "{{event.value}}") },
        { type: "select", label: "Lead Source", binding: "app.form.source", items: [{ value: "inbound", label: "Inbound" }, { value: "partner", label: "Partner" }, { value: "event", label: "Event" }] },
        { type: "textInput", label: "Notes", binding: "app.form.notes", maxLines: 4, placeholder: "Enter follow-up notes" },
      ],
    },
    orders: {
      state: { orderNo: "SO-2026-0148", owner: "Fulfillment Team", priority: "high", refundAmount: 1800, channel: "email", notes: "Customer requested same-day callback." },
      fields: [
        { type: "textInput", label: "Order No.", binding: "app.form.orderNo", placeholder: "Enter order number" },
        { type: "textInput", label: "Owner", binding: "app.form.owner", placeholder: "Enter queue owner" },
        { type: "select", label: "Priority", binding: "app.form.priority", items: [{ value: "low", label: "Low" }, { value: "medium", label: "Medium" }, { value: "high", label: "High" }] },
        { type: "numberField", label: "Refund Amount", value: { binding: "app.form.refundAmount" }, prefix: "$ ", step: 100, change: stateAction("app.form.refundAmount", "set", "{{event.value}}") },
        { type: "select", label: "Contact Channel", binding: "app.form.channel", items: [{ value: "email", label: "Email" }, { value: "phone", label: "Phone" }, { value: "wechat", label: "WeChat" }] },
        { type: "textInput", label: "Resolution Notes", binding: "app.form.notes", maxLines: 4, placeholder: "Enter resolution notes" },
      ],
    },
    service: {
      state: { serviceName: "Inventory API", owner: "Platform Team", severity: "high", errorBudget: 12, channel: "slack", notes: "Escalate if p95 exceeds 200ms." },
      fields: [
        { type: "textInput", label: "Service", binding: "app.form.serviceName", placeholder: "Enter service name" },
        { type: "textInput", label: "Owner", binding: "app.form.owner", placeholder: "Enter service owner" },
        { type: "select", label: "Severity", binding: "app.form.severity", items: [{ value: "low", label: "Low" }, { value: "medium", label: "Medium" }, { value: "high", label: "High" }] },
        { type: "numberField", label: "Error Budget Burn", value: { binding: "app.form.errorBudget" }, step: 1, change: stateAction("app.form.errorBudget", "set", "{{event.value}}") },
        { type: "select", label: "Escalation Channel", binding: "app.form.channel", items: [{ value: "slack", label: "Slack" }, { value: "email", label: "Email" }, { value: "pager", label: "Pager" }] },
        { type: "textInput", label: "Notes", binding: "app.form.notes", maxLines: 4, placeholder: "Enter incident notes" },
      ],
    },
    approval: {
      state: { requestName: "Regional campaign approval", owner: "Operations Team", priority: "high", budget: 120000, channel: "email", notes: "Coordinate sales, support, and logistics before launch." },
      fields: [
        { type: "textInput", label: "Request Name", binding: "app.form.requestName", placeholder: "Enter request name" },
        { type: "textInput", label: "Owner", binding: "app.form.owner", placeholder: "Enter owner" },
        { type: "select", label: "Priority", binding: "app.form.priority", items: [{ value: "low", label: "Low" }, { value: "medium", label: "Medium" }, { value: "high", label: "High" }] },
        { type: "numberField", label: "Budget", value: { binding: "app.form.budget" }, prefix: "$ ", step: 1000, change: stateAction("app.form.budget", "set", "{{event.value}}") },
        { type: "select", label: "Notify Via", binding: "app.form.channel", items: [{ value: "email", label: "Email" }, { value: "wechat", label: "WeChat" }, { value: "sms", label: "SMS" }] },
        { type: "textInput", label: "Notes", binding: "app.form.notes", maxLines: 4, placeholder: "Enter supporting notes" },
      ],
    },
    inventory: {
      state: { sku: "SKU-8821", owner: "Warehouse Ops", severity: "high", reorderPoint: 24, channel: "email", notes: "Trigger replenishment before next promo." },
      fields: [
        { type: "textInput", label: "SKU", binding: "app.form.sku", placeholder: "Enter SKU" },
        { type: "textInput", label: "Owner", binding: "app.form.owner", placeholder: "Enter stock owner" },
        { type: "select", label: "Severity", binding: "app.form.severity", items: [{ value: "low", label: "Low" }, { value: "medium", label: "Medium" }, { value: "high", label: "High" }] },
        { type: "numberField", label: "Reorder Point", value: { binding: "app.form.reorderPoint" }, step: 1, change: stateAction("app.form.reorderPoint", "set", "{{event.value}}") },
        { type: "select", label: "Notify Via", binding: "app.form.channel", items: [{ value: "email", label: "Email" }, { value: "wechat", label: "WeChat" }, { value: "sms", label: "SMS" }] },
        { type: "textInput", label: "Notes", binding: "app.form.notes", maxLines: 4, placeholder: "Enter stock notes" },
      ],
    },
  };

  const preset = fieldsByScenario[scenario];
  const normalizedFields = preset.fields.map((field) => normalizeFormField(field));
  return {
    description: `AI generated form draft for "${promptSnippet(prompt)}".`,
    definition: {
      type: "page",
      title,
      state: { initial: { form: preset.state, statusText: "Draft" } },
      content: {
        type: "linear",
        direction: "vertical",
        gap: 16,
        children: [
          { type: "form", title: `${title} Intake`, subtitle: `Generated from: ${promptSnippet(prompt)}`, children: normalizedFields },
          { type: "antdSection", title: "Actions", subtitle: "Current status: {{app.statusText}}", child: { type: "linear", direction: "horizontal", gap: 12, wrap: true, children: [{ type: "button", label: "Submit", variant: "outlined", click: stateAction("app.statusText", "set", "Submitted for review") }, { type: "button", label: "Save draft", variant: "filled", backgroundColor: "#0f766e", click: persistAction() }] } },
        ],
      },
    },
  };
}

function tablePreset(
  title: string,
  prompt: string,
  scenario: Scenario,
): { definition: JsonObject; description: string } {
  const rowsByScenario: Record<Scenario, { statusText: string; columns: JsonObject[]; rows: JsonObject[] }> = {
    sales: { statusText: "Ready for revenue review", columns: [{ key: "initiative", title: "Initiative" }, { key: "owner", title: "Owner" }, { key: "status", title: "Status" }, { key: "amount", title: "Amount" }], rows: [{ initiative: "Enterprise expansion", owner: "Regional Sales", status: "healthy", amount: "$480K" }, { initiative: "Partner co-sell", owner: "Channel Team", status: "watch", amount: "$210K" }, { initiative: "Renewal recovery", owner: "CS Team", status: "degraded", amount: "$96K" }] },
    customer: { statusText: "Prioritize top accounts", columns: [{ key: "customer", title: "Customer" }, { key: "owner", title: "Owner" }, { key: "stage", title: "Stage" }, { key: "nextTouch", title: "Next Touch" }], rows: [{ customer: "Northwind Retail", owner: "Ava Chen", stage: "Proposal", nextTouch: "Tomorrow" }, { customer: "BluePeak Health", owner: "Leo Tan", stage: "Qualified", nextTouch: "Friday" }, { customer: "Orion Foods", owner: "Mia Zhao", stage: "Negotiation", nextTouch: "Today" }] },
    orders: { statusText: "Ready for manual review", columns: [{ key: "orderNo", title: "Order No." }, { key: "owner", title: "Owner" }, { key: "status", title: "Status" }, { key: "amount", title: "Amount" }], rows: [{ orderNo: "SO-2026-0148", owner: "Fulfillment", status: "healthy", amount: "$8,420" }, { orderNo: "SO-2026-0153", owner: "Finance Ops", status: "watch", amount: "$1,980" }, { orderNo: "SO-2026-0162", owner: "CX Team", status: "degraded", amount: "$640" }] },
    service: { statusText: "Watch latency spikes before release", columns: [{ key: "service", title: "Service" }, { key: "owner", title: "Owner" }, { key: "status", title: "Status" }, { key: "latency", title: "P95" }], rows: [{ service: "Order API", owner: "Traffic Team", status: "healthy", latency: "92ms" }, { service: "Inventory API", owner: "Supply Team", status: "watch", latency: "164ms" }, { service: "Notification API", owner: "Platform Team", status: "degraded", latency: "228ms" }] },
    approval: { statusText: "Approval queue staged", columns: [{ key: "request", title: "Request" }, { key: "owner", title: "Owner" }, { key: "status", title: "Status" }, { key: "eta", title: "ETA" }], rows: [{ request: "Campaign launch", owner: "Ops Team", status: "healthy", eta: "Today" }, { request: "Budget exception", owner: "Finance Team", status: "watch", eta: "Tomorrow" }, { request: "Vendor onboarding", owner: "Procurement", status: "degraded", eta: "Friday" }] },
    inventory: { statusText: "Replenishment queue staged", columns: [{ key: "sku", title: "SKU" }, { key: "warehouse", title: "Warehouse" }, { key: "status", title: "Status" }, { key: "available", title: "Available" }], rows: [{ sku: "SKU-8821", warehouse: "Hangzhou", status: "watch", available: "18" }, { sku: "SKU-1093", warehouse: "Shenzhen", status: "healthy", available: "142" }, { sku: "SKU-5510", warehouse: "Chengdu", status: "degraded", available: "6" }] },
  };

  const preset = rowsByScenario[scenario];
  return {
    description: `AI generated list draft for "${promptSnippet(prompt)}".`,
    definition: {
      type: "page",
      title,
      state: { initial: { rows: preset.rows, statusText: preset.statusText, filters: { keyword: "", status: "all" } } },
      content: {
        type: "linear",
        direction: "vertical",
        gap: 16,
        children: [
          { type: "searchBar", label: "Search", binding: "app.filters.keyword", placeholder: "Search rows by keyword", buttonLabel: "Apply", searchAction: stateAction("app.statusText", "set", "Filters applied"), filters: [{ type: "select", label: "Status", binding: "app.filters.status", items: [{ value: "all", label: "All" }, { value: "healthy", label: "Healthy" }, { value: "watch", label: "Watch" }, { value: "degraded", label: "Degraded" }] }] },
          { type: "antdSection", title: `${title} Overview`, subtitle: `Generated from: ${promptSnippet(prompt)}`, child: { type: "antdTable", columns: preset.columns, rows: { binding: "app.rows" } } },
          { type: "antdSection", title: "Actions", subtitle: "{{app.statusText}}", child: { type: "linear", direction: "horizontal", gap: 12, wrap: true, children: [{ type: "button", label: "Mark reviewed", variant: "outlined", click: stateAction("app.statusText", "set", "Checked by reviewer") }, { type: "button", label: "Save page", variant: "filled", backgroundColor: "#0f766e", click: persistAction() }] } },
        ],
      },
    },
  };
}

function applyPersistParams(definition: JsonObject, slug: string, title: string, description: string): void {
  const content = definition.content;
  if (!isObject(content) || !Array.isArray(content.children)) {
    return;
  }

  for (const child of content.children) {
    if (!isObject(child)) {
      continue;
    }
    const nested = child.child;
    if (!isObject(nested) || !Array.isArray(nested.children)) {
      continue;
    }
    for (const nestedChild of nested.children) {
      if (!isObject(nestedChild) || nestedChild.type !== "button") {
        continue;
      }
      const click = nestedChild.click;
      if (!isObject(click) || click.type !== "tool" || click.tool !== "persistPage") {
        continue;
      }
      click.params = { slug, title, description, note: "Saved from AI generated draft" };
      return;
    }
  }
}

export const COMPONENT_CATALOG: ComponentCatalogItem[] = [
  { name: "page", category: "layout", description: "Page root with state and content.", recommendedForAi: true, props: [{ name: "title", type: "string", required: true, description: "Display title." }, { name: "state", type: "object", description: "Initial runtime state." }, { name: "content", type: "object", required: true, description: "Root widget node." }], sample: { type: "page", title: "Sample Page", content: { type: "linear", direction: "vertical", children: [] } } },
  { name: "linear", category: "layout", description: "Simple vertical or horizontal container.", recommendedForAi: true, props: [{ name: "direction", type: "string", description: "vertical or horizontal." }, { name: "gap", type: "number", description: "Space between children." }, { name: "wrap", type: "boolean", description: "Enable wrapping for rows." }, { name: "children", type: "array", required: true, description: "Nested components." }], sample: { type: "linear", direction: "vertical", gap: 16, children: [] } },
  { name: "button", category: "action", description: "Clickable action button.", recommendedForAi: true, props: [{ name: "label", type: "string", required: true, description: "Button label." }, { name: "variant", type: "string", description: "filled or outlined." }, { name: "click", type: "object", description: "State or tool action." }], sample: { type: "button", label: "Save draft", variant: "filled", click: { type: "tool", tool: "persistPage", params: {} } } },
  { name: "select", category: "data-entry", description: "Selectable dropdown bound to state.", recommendedForAi: true, props: [{ name: "label", type: "string", required: true, description: "Field label." }, { name: "binding", type: "string", required: true, description: "State binding path." }, { name: "items", type: "array", required: true, description: "Options." }], sample: { type: "select", label: "Priority", binding: "app.form.priority", items: [{ value: "low", label: "Low" }, { value: "high", label: "High" }] } },
  { name: "text", category: "display", description: "Plain text block.", recommendedForAi: true, props: [{ name: "content", type: "string", required: true, description: "Display content." }], sample: { type: "text", content: "Helpful note for the operator." } },
  { name: "textInput", category: "data-entry", description: "Bound text input field.", recommendedForAi: true, props: [{ name: "label", type: "string", required: true, description: "Field label." }, { name: "binding", type: "string", required: true, description: "State binding path." }, { name: "placeholder", type: "string", description: "Input placeholder." }, { name: "maxLines", type: "number", description: "Optional multiline rows." }], sample: { type: "textInput", label: "Customer Name", binding: "app.form.customerName", placeholder: "Enter customer name" } },
  { name: "input", category: "data-entry", description: "Alias of textInput for single-line forms.", recommendedForAi: true, props: [{ name: "label", type: "string", required: true, description: "Field label." }, { name: "binding", type: "string", required: true, description: "State binding path." }, { name: "placeholder", type: "string", description: "Input placeholder." }], sample: { type: "input", label: "Customer Name", binding: "app.form.customerName", placeholder: "Enter customer name" } },
  { name: "textarea", category: "data-entry", description: "Multiline text input for notes or descriptions.", recommendedForAi: true, props: [{ name: "label", type: "string", required: true, description: "Field label." }, { name: "binding", type: "string", required: true, description: "State binding path." }, { name: "placeholder", type: "string", description: "Input placeholder." }, { name: "maxLines", type: "number", description: "Visible line count." }], sample: { type: "textarea", label: "Notes", binding: "app.form.notes", placeholder: "Enter supporting notes", maxLines: 4 } },
  { name: "numberField", category: "data-entry", description: "Numeric input with explicit change action.", recommendedForAi: true, props: [{ name: "label", type: "string", required: true, description: "Field label." }, { name: "value", type: "object", required: true, description: "Current bound value." }, { name: "change", type: "object", description: "State update action." }, { name: "step", type: "number", description: "Increment step." }], sample: { type: "numberField", label: "Budget", value: { binding: "app.form.budget" }, step: 1000, change: { type: "state", action: "set", binding: "app.form.budget", value: "{{event.value}}" } } },
  { name: "form", category: "layout", description: "Structured form container for grouped data-entry fields.", recommendedForAi: true, props: [{ name: "title", type: "string", description: "Form title." }, { name: "subtitle", type: "string", description: "Form helper text." }, { name: "children", type: "array", description: "Nested fields in display order." }, { name: "child", type: "object", description: "Optional single nested layout node." }], sample: { type: "form", title: "Approval Form", subtitle: "Collect request details.", children: [{ type: "input", label: "Request Name", binding: "app.form.requestName" }, { type: "textarea", label: "Notes", binding: "app.form.notes", maxLines: 4 }] } },
  { name: "searchBar", category: "data-entry", description: "Convenience search/filter container for list pages.", recommendedForAi: true, props: [{ name: "label", type: "string", description: "Keyword field label." }, { name: "binding", type: "string", required: true, description: "State binding path for the keyword." }, { name: "placeholder", type: "string", description: "Search placeholder." }, { name: "filters", type: "array", description: "Extra filter widgets appended after the search box." }, { name: "searchAction", type: "object", description: "Optional action fired by the search button." }], sample: { type: "searchBar", label: "Search Orders", binding: "app.filters.keyword", placeholder: "Search order no.", filters: [{ type: "select", label: "Status", binding: "app.filters.status", items: [{ value: "all", label: "All" }, { value: "healthy", label: "Healthy" }] }], searchAction: { type: "state", action: "set", binding: "app.statusText", value: "Filters updated" } } },
  { name: "antdSection", category: "display", description: "Card-style section container.", recommendedForAi: true, props: [{ name: "title", type: "string", required: true, description: "Section title." }, { name: "subtitle", type: "string", description: "Secondary description." }, { name: "child", type: "object", required: true, description: "Nested component." }], sample: { type: "antdSection", title: "Overview", subtitle: "Short context for the section.", child: { type: "text", content: "Section content" } } },
  { name: "antdStat", category: "display", description: "KPI card with value and trend.", recommendedForAi: true, props: [{ name: "title", type: "string", required: true, description: "Metric title." }, { name: "value", type: "string", required: true, description: "Metric value." }, { name: "suffix", type: "string", description: "Optional unit." }, { name: "trend", type: "string", description: "Trend label." }, { name: "tone", type: "string", description: "Visual accent tone." }], sample: { type: "antdStat", title: "Revenue", value: "4.8", suffix: "M", trend: "+18%", tone: "teal" } },
  { name: "antdTable", category: "data-display", description: "Antd-style table with columns and rows.", recommendedForAi: true, props: [{ name: "columns", type: "array", required: true, description: "Table columns." }, { name: "rows", type: "array|object", required: true, description: "Rows or binding." }], sample: { type: "antdTable", columns: [{ key: "name", title: "Name" }, { key: "status", title: "Status" }], rows: [{ name: "Order API", status: "healthy" }] } },
];

const COMPONENT_NAMES = new Set(COMPONENT_CATALOG.map((item) => item.name));
const ACTION_TYPES = new Set(["state", "tool", "resource", "data", "navigation", "submit"]);

function pushIssue(
  target: ValidationIssue[],
  path: string,
  message: string,
  suggestion?: string,
): void {
  target.push({ path, message, suggestion });
}

function validateAction(value: unknown, path: string, context: ValidationContext): void {
  if (!isObject(value)) {
    pushIssue(context.errors, path, "Action must be an object.");
    return;
  }

  const type = typeof value.type === "string" ? value.type : "";
  if (!ACTION_TYPES.has(type)) {
    pushIssue(
      context.errors,
      `${path}.type`,
      `Unsupported action type "${String(value.type ?? "")}".`,
      "Use state, tool, resource, data, navigation, or submit.",
    );
    return;
  }

  if (type === "tool" && typeof value.tool !== "string") {
    pushIssue(context.errors, `${path}.tool`, "Tool actions require a tool name.");
  }
}

function validateComponent(node: unknown, path: string, context: ValidationContext): void {
  if (!isObject(node)) {
    pushIssue(context.errors, path, "Component node must be an object.");
    return;
  }

  const type = typeof node.type === "string" ? node.type : "";
  if (!type) {
    pushIssue(context.errors, `${path}.type`, "Component type is required.");
    return;
  }
  if (!COMPONENT_NAMES.has(type)) {
    pushIssue(
      context.errors,
      `${path}.type`,
      `Unsupported component type "${type}".`,
      "Use list_components to inspect the current whitelist.",
    );
    return;
  }
  context.usedComponents.add(type);

  if (type === "linear") {
    if (!Array.isArray(node.children)) {
      pushIssue(context.errors, `${path}.children`, "linear.children must be an array.");
      return;
    }
    if (typeof node.direction !== "string") {
      pushIssue(context.warnings, `${path}.direction`, "linear.direction is missing.", "The server will normalize it to vertical.");
    }
    node.children.forEach((child, index) => {
      validateComponent(child, `${path}.children[${index}]`, context);
    });
    return;
  }

  if (type === "button") {
    if (typeof node.label !== "string" || node.label.trim().length === 0) {
      pushIssue(context.errors, `${path}.label`, "button.label is required.");
    }
    if (node.click !== undefined) {
      validateAction(node.click, `${path}.click`, context);
    }
    return;
  }

  if (type === "select") {
    if (typeof node.label !== "string" || node.label.trim().length === 0) {
      pushIssue(context.errors, `${path}.label`, "select.label is required.");
    }
    if (typeof node.binding !== "string" || node.binding.trim().length === 0) {
      pushIssue(context.errors, `${path}.binding`, "select.binding is required.");
    }
    if (!Array.isArray(node.items) || node.items.length === 0) {
      pushIssue(context.errors, `${path}.items`, "select.items must be a non-empty array.");
    }
    return;
  }

  if (type === "text") {
    if (typeof node.content !== "string" || node.content.trim().length === 0) {
      pushIssue(context.errors, `${path}.content`, "text.content is required.");
    }
    return;
  }

  if (type === "textInput") {
    if (typeof node.label !== "string" || node.label.trim().length === 0) {
      pushIssue(context.errors, `${path}.label`, "textInput.label is required.");
    }
    if (typeof node.binding !== "string" || node.binding.trim().length === 0) {
      pushIssue(context.errors, `${path}.binding`, "textInput.binding is required.");
    }
    return;
  }

  if (type === "input" || type === "textarea") {
    if (typeof node.label !== "string" || node.label.trim().length === 0) {
      pushIssue(context.errors, `${path}.label`, `${type}.label is required.`);
    }
    if (typeof node.binding !== "string" || node.binding.trim().length === 0) {
      pushIssue(context.errors, `${path}.binding`, `${type}.binding is required.`);
    }
    return;
  }

  if (type === "numberField") {
    if (typeof node.label !== "string" || node.label.trim().length === 0) {
      pushIssue(context.errors, `${path}.label`, "numberField.label is required.");
    }
    if (!isObject(node.value)) {
      pushIssue(context.errors, `${path}.value`, "numberField.value must be an object, usually a binding.");
    }
    if (node.change !== undefined) {
      validateAction(node.change, `${path}.change`, context);
    }
    return;
  }

  if (type === "form") {
    const hasChild = isObject(node.child);
    const hasChildren = Array.isArray(node.children) && node.children.length > 0;
    if (!hasChild && !hasChildren) {
      pushIssue(context.errors, path, "form requires child or children.");
      return;
    }
    if (hasChild) {
      validateComponent(node.child, `${path}.child`, context);
    }
    if (Array.isArray(node.children)) {
      node.children.forEach((child, index) => {
        validateComponent(child, `${path}.children[${index}]`, context);
      });
    }
    return;
  }

  if (type === "searchBar") {
    if (typeof node.binding !== "string" || node.binding.trim().length === 0) {
      pushIssue(context.errors, `${path}.binding`, "searchBar.binding is required.");
    }
    if (node.filters !== undefined) {
      if (!Array.isArray(node.filters)) {
        pushIssue(context.errors, `${path}.filters`, "searchBar.filters must be an array.");
      } else {
        node.filters.forEach((filter, index) => {
          validateComponent(filter, `${path}.filters[${index}]`, context);
        });
      }
    }
    if (node.actions !== undefined) {
      if (!Array.isArray(node.actions)) {
        pushIssue(context.errors, `${path}.actions`, "searchBar.actions must be an array.");
      } else {
        node.actions.forEach((actionNode, index) => {
          validateComponent(actionNode, `${path}.actions[${index}]`, context);
        });
      }
    }
    if (node.searchAction !== undefined) {
      validateAction(node.searchAction, `${path}.searchAction`, context);
    }
    return;
  }

  if (type === "antdSection") {
    if (typeof node.title !== "string" || node.title.trim().length === 0) {
      pushIssue(context.errors, `${path}.title`, "antdSection.title is required.");
    }
    validateComponent(node.child, `${path}.child`, context);
    return;
  }

  if (type === "antdStat") {
    if (typeof node.title !== "string" || node.title.trim().length === 0) {
      pushIssue(context.errors, `${path}.title`, "antdStat.title is required.");
    }
    if (node.value === undefined) {
      pushIssue(context.errors, `${path}.value`, "antdStat.value is required.");
    }
    return;
  }

  if (type === "antdTable") {
    if (!Array.isArray(node.columns) || node.columns.length === 0) {
      pushIssue(context.errors, `${path}.columns`, "antdTable.columns must be a non-empty array.");
    } else {
      node.columns.forEach((column, index) => {
        if (!isObject(column) || typeof column.key !== "string" || typeof column.title !== "string") {
          pushIssue(context.errors, `${path}.columns[${index}]`, "Each table column requires key and title.");
        }
      });
    }
    if (!Array.isArray(node.rows) && (!isObject(node.rows) || typeof node.rows.binding !== "string")) {
      pushIssue(context.errors, `${path}.rows`, "antdTable.rows must be an array or a binding object.");
    }
  }
}

function normalizeDefinition(input: JsonObject): JsonObject {
  const normalized = cloneJson(input);
  normalized.type = "page";
  if (typeof normalized.title !== "string" || normalized.title.trim().length === 0) {
    normalized.title = "Untitled Page";
  }

  if (!isObject(normalized.content)) {
    normalized.content = {
      type: "linear",
      direction: "vertical",
      gap: 16,
      children: [],
    };
    return normalized;
  }

  const content = normalized.content;
  if (content.type === "linear") {
    if (typeof content.direction !== "string") {
      content.direction = "vertical";
    }
    if (typeof content.gap !== "number") {
      content.gap = 16;
    }
    if (!Array.isArray(content.children)) {
      content.children = [];
    }
  }

  return normalized;
}

export function validatePageDefinition(definition: JsonObject): ValidatePageResult {
  const normalizedDefinition = normalizeDefinition(definition);
  const context: ValidationContext = {
    errors: [],
    warnings: [],
    usedComponents: new Set(["page"]),
  };

  if (definition.type !== "page") {
    pushIssue(context.errors, "type", 'Page root type must be "page".', "Wrap the definition in a page root before rendering.");
  }
  if (!isObject(definition.content)) {
    pushIssue(context.errors, "content", "Page content must be an object.");
  } else {
    validateComponent(definition.content, "content", context);
  }
  if (!isObject(definition.state)) {
    pushIssue(context.warnings, "state", "Page state is missing.", "Add state.initial if the page relies on bindings.");
  }

  return {
    valid: context.errors.length === 0,
    errors: context.errors,
    warnings: context.warnings,
    normalizedDefinition,
    usedComponents: Array.from(context.usedComponents).sort(),
  };
}

export function listComponentCatalog(input: ListComponentsInput = {}): ComponentCatalogItem[] {
  const category = typeof input.category === "string" && input.category.trim().length > 0
    ? input.category.trim().toLowerCase()
    : null;
  return COMPONENT_CATALOG.filter((item) => {
    if (category && item.category.toLowerCase() !== category) {
      return false;
    }
    if (input.recommendedOnly === true && item.recommendedForAi !== true) {
      return false;
    }
    return true;
  }).map((item) => cloneJson(item));
}

export function generatePageFromPrompt(input: GeneratePageFromPromptInput): GeneratedPageResult {
  const prompt = input.prompt.trim();
  if (!prompt) {
    throw new Error("prompt is required.");
  }

  const pageType = inferPageType(input);
  const scenario = inferScenario(prompt, pageType);
  const title = input.title?.trim() || buildTitle(prompt, pageType);
  const slug = resolveSlug(input.slug, prompt, title, pageType);
  const preset = pageType === "form"
    ? formPreset(title, prompt, scenario)
    : pageType === "table-list"
      ? tablePreset(title, prompt, scenario)
      : dashboardPreset(title, prompt, scenario);

  applyPersistParams(preset.definition, slug, title, preset.description);
  const validation = validatePageDefinition(preset.definition);

  return {
    slug,
    title,
    pageType,
    seedTemplate: typeof input.seedTemplate === "string" && input.seedTemplate.trim().length > 0
      ? input.seedTemplate.trim()
      : undefined,
    definition: validation.normalizedDefinition,
    summary: `Generated a ${pageType} draft for the ${scenario} scenario based on "${promptSnippet(prompt)}".`,
    warnings: validation.warnings.map((warning) => `${warning.path}: ${warning.message}`),
    usedComponents: validation.usedComponents,
    assumptions: [
      `Interpreted the request as a ${pageType} page.`,
      `Applied the ${scenario} preset to keep the draft renderable without external data.`,
      "Kept actions limited to supported state and tool flows.",
      ...(input.seedTemplate ? [`Used "${input.seedTemplate}" as a layout hint.`] : []),
      ...(input.locale ? [`Generated copy for locale "${input.locale}".`] : []),
    ],
  };
}

export function updatePageByInstruction(
  input: UpdatePageByInstructionInput,
): UpdatePageByInstructionResult {
  const instruction = input.instruction.trim();
  if (!instruction) {
    throw new Error("instruction is required.");
  }

  const baseValidation = validatePageDefinition(input.definition);
  const updatedDefinition = cloneJson(baseValidation.normalizedDefinition);
  const appliedChanges: string[] = [];
  const warnings: string[] = [];

  if (baseValidation.errors.length > 0) {
    warnings.push(
      "The source page had validation errors; the updater normalized the root before applying changes.",
    );
  }

  const requestedTitle = extractRequestedTitle(instruction);
  if (requestedTitle) {
    updatedDefinition.title = requestedTitle;
    appliedChanges.push(`Updated the page title to "${requestedTitle}".`);
  }

  addInstructionWarnings(instruction, warnings);

  const initialState = ensureStateInitial(updatedDefinition);
  const addSection = (section: JsonObject, summary: string) => {
    appendRootChild(updatedDefinition, section);
    appliedChanges.push(summary);
  };

  if (/(?:kpi|metric|stat|指标)/i.test(instruction)) {
    addSection(buildKpiSection("KPI Highlights"), "Added a KPI highlights section.");
  }

  if (/(?:search|filter|筛选|搜索)/i.test(instruction)) {
    initialState.filters = isObject(initialState.filters)
      ? initialState.filters
      : { keyword: "", status: "all" };
    initialState.statusText = typeof initialState.statusText === "string"
      ? initialState.statusText
      : "Filters ready";
    const change = upsertSearchSection(updatedDefinition);
    appliedChanges.push(
      change === "added"
        ? "Added search and status filter controls."
        : "Updated the existing search and status filter controls.",
    );
  }

  if (/(?:table|list|grid|queue|表格|列表|清单)/i.test(instruction)) {
    addSection(buildTableSection("Generated Table Block"), "Added a data table section.");
  }

  if (/(?:form|field|input|表单|字段|录入)/i.test(instruction)) {
    initialState.form = isObject(initialState.form)
      ? initialState.form
      : { requestName: "", priority: "medium", budget: 0 };
    addSection(buildFormSection("Generated Form Block"), "Added a form input section.");
  }

  if (/(?:action|button|toolbar|操作|按钮)/i.test(instruction)) {
    initialState.statusText = typeof initialState.statusText === "string"
      ? initialState.statusText
      : "Ready";
    const change = upsertToolbarSection(updatedDefinition);
    appliedChanges.push(
      change === "added"
        ? "Added an action toolbar section."
        : "Updated the existing action toolbar section.",
    );
  }

  if (/(?:note|summary|说明|备注|描述)/i.test(instruction)) {
    addSection(buildNoteSection("Instruction Notes", instruction), "Added a note section.");
  }

  if (appliedChanges.length === 0) {
    addSection(
      buildNoteSection("AI Follow-up Needed", instruction),
      "Captured the instruction as a follow-up note for manual refinement.",
    );
    warnings.push(
      "The instruction could not be mapped to a structured Sprint 1 edit, so a note block was added instead.",
    );
  }

  const validation = validatePageDefinition(updatedDefinition);
  warnings.push(
    ...validation.warnings.map((warning) => `${warning.path}: ${warning.message}`),
  );

  return {
    title: String(validation.normalizedDefinition.title ?? "Untitled Page"),
    definition: validation.normalizedDefinition,
    summary: `Applied ${appliedChanges.length} AI refinement change${appliedChanges.length === 1 ? "" : "s"}.`,
    warnings,
    usedComponents: validation.usedComponents,
    assumptions: [
      "Applied rule-based edits within the Sprint 1 component whitelist.",
      "Preserved the existing page structure unless the root had to be wrapped into a linear layout.",
      ...(input.locale ? [`Kept update copy compatible with locale "${input.locale}".`] : []),
    ],
    appliedChanges,
  };
}
