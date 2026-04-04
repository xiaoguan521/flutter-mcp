import { normalizeSlug } from "./uri.js";
import type {
  CreateAppInput,
  GenerateAppFromPromptInput,
  ValidateAppResult,
  ValidationIssue,
  JsonObject,
} from "./types.js";

type AppPageSeed = {
  slug: string;
  title: string;
  pageUri: string;
};

type GeneratedAppPagePlan = {
  slug: string;
  title: string;
  pageType: "dashboard" | "table-list" | "form";
  promptHint: string;
};

type AppPromptBlueprint = {
  name: string;
  slug: string;
  description: string;
  navigationStyle: string;
  pages: GeneratedAppPagePlan[];
  summary: string;
  assumptions: string[];
};

function pushIssue(
  target: ValidationIssue[],
  path: string,
  message: string,
  suggestion?: string,
): void {
  target.push({ path, message, suggestion });
}

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function defaultBuildProfiles(): JsonObject[] {
  return [
    {
      id: "web-debug",
      target: "web",
      mode: "debug",
    },
    {
      id: "android-debug",
      target: "android",
      mode: "debug",
    },
  ];
}

function truncateText(value: string, maxLength: number): string {
  const trimmed = value.trim();
  if (trimmed.length <= maxLength) {
    return trimmed;
  }
  return `${trimmed.slice(0, Math.max(0, maxLength - 3))}...`;
}

function inferDomain(prompt: string): {
  noun: string;
  dashboardTitle: string;
  listTitle: string;
  formTitle: string;
  listHint: string;
  formHint: string;
} {
  const lower = prompt.toLowerCase();
  if (/订单|order|fulfillment|shipment/.test(prompt) || /order|fulfillment|shipment/.test(lower)) {
    return {
      noun: "订单",
      dashboardTitle: "订单总览",
      listTitle: "订单列表",
      formTitle: "订单详情",
      listHint: "列表页，展示状态、负责人、时间和操作按钮",
      formHint: "详情或编辑页，展示订单关键信息和审批/处理表单",
    };
  }
  if (/客户|customer|crm|lead/.test(prompt) || /customer|crm|lead/.test(lower)) {
    return {
      noun: "客户",
      dashboardTitle: "客户总览",
      listTitle: "客户列表",
      formTitle: "客户详情",
      listHint: "列表页，展示搜索、筛选、负责人和状态列",
      formHint: "详情或编辑页，展示客户档案、负责人和备注表单",
    };
  }
  if (/商品|product|inventory|sku/.test(prompt) || /product|inventory|sku/.test(lower)) {
    return {
      noun: "商品",
      dashboardTitle: "商品运营总览",
      listTitle: "商品列表",
      formTitle: "商品编辑",
      listHint: "列表页，展示库存、状态、负责人和搜索筛选",
      formHint: "编辑页，展示商品信息、库存和上下架配置表单",
    };
  }
  return {
    noun: "业务",
    dashboardTitle: "业务总览",
    listTitle: "业务列表",
    formTitle: "业务配置",
    listHint: "列表页，展示搜索、筛选、状态列和操作按钮",
    formHint: "配置页，展示基础信息、负责人和备注表单",
  };
}

export function generateAppBlueprint(
  input: GenerateAppFromPromptInput,
): AppPromptBlueprint {
  const prompt = input.prompt.trim();
  const domain = inferDomain(prompt);
  const baseName = truncateText(prompt, 16);
  const name = typeof input.name === "string" && input.name.trim().length > 0
    ? input.name.trim()
    : baseName
      ? `${baseName} 应用`
      : `${domain.noun}管理应用`;
  const slug = normalizeSlug(input.slug ?? name);
  const navigationStyle = typeof input.navigationStyle === "string"
    && input.navigationStyle.trim().length > 0
    ? input.navigationStyle.trim()
    : /tabs|tab|标签/.test(prompt.toLowerCase())
      ? "tabs"
      : /top|topbar|顶部/.test(prompt.toLowerCase())
        ? "topbar"
        : "sidebar";

  const pages: GeneratedAppPagePlan[] = [
    {
      slug: `${slug}-dashboard`,
      title: domain.dashboardTitle,
      pageType: "dashboard",
      promptHint: `${prompt}，首页仪表盘，包含核心 KPI、趋势和提醒模块`,
    },
    {
      slug: `${slug}-list`,
      title: domain.listTitle,
      pageType: "table-list",
      promptHint: `${prompt}，${domain.listHint}`,
    },
    {
      slug: `${slug}-detail`,
      title: domain.formTitle,
      pageType: "form",
      promptHint: `${prompt}，${domain.formHint}`,
    },
  ];

  if (/设置|setting|config/.test(prompt) || /setting|config/.test(prompt.toLowerCase())) {
    pages.push({
      slug: `${slug}-settings`,
      title: "系统设置",
      pageType: "form",
      promptHint: `${prompt}，系统设置页，展示主题、通知和权限配置表单`,
    });
  }

  return {
    name,
    slug,
    description: `AI generated multi-page app skeleton for: ${truncateText(prompt, 72)}`,
    navigationStyle,
    pages,
    summary: `Generated ${pages.length} pages for a ${navigationStyle} application shell.`,
    assumptions: [
      "Used one dashboard page as the home entry.",
      "Used one table/list page for the primary collection workflow.",
      "Used one form page for detail or settings editing.",
    ],
  };
}

export function createAppSchema(
  input: CreateAppInput,
  pages: AppPageSeed[],
): JsonObject {
  const slug = normalizeSlug(input.slug ?? input.name);
  const navigationStyle = typeof input.navigationStyle === "string"
    && input.navigationStyle.trim().length > 0
    ? input.navigationStyle.trim()
    : "sidebar";
  const resolvedPages = pages.map((page) => ({
    slug: normalizeSlug(page.slug),
    title: page.title,
    pageUri: page.pageUri,
  }));
  const routes = resolvedPages.map((page, index) => ({
    id: `route-${page.slug}`,
    path: index === 0 ? "/" : `/${page.slug}`,
    pageSlug: page.slug,
    pageUri: page.pageUri,
    title: page.title,
  }));

  return {
    type: "app",
    appId: `app-${slug}`,
    slug,
    name: input.name.trim(),
    description: input.description?.trim() || undefined,
    theme: {
      mode: "light",
      primaryColor: "#0f766e",
    },
    layoutShell: {
      type: navigationStyle === "tabs"
        ? "tabsShell"
        : navigationStyle === "topbar"
        ? "topNavShell"
        : "sidebarShell",
      navigationStyle,
    },
    pages: resolvedPages,
    routes,
    navigation: routes.map((route) => ({
      label: route.title,
      route: route.path,
      pageSlug: route.pageSlug,
    })),
    homePage: resolvedPages[0]?.slug,
    auth: {
      required: false,
    },
    globalState: {
      initial: {},
    },
    dataSources: [],
    buildProfiles: defaultBuildProfiles(),
  };
}

export function validateAppSchema(schema: JsonObject): ValidateAppResult {
  const normalized = JSON.parse(JSON.stringify(schema)) as JsonObject;
  const errors: ValidationIssue[] = [];
  const warnings: ValidationIssue[] = [];

  normalized.type = "app";
  if (typeof normalized.slug !== "string" || normalized.slug.trim().length === 0) {
    const fallback = typeof normalized.name === "string"
      ? normalizeSlug(normalized.name)
      : "app";
    normalized.slug = fallback || "app";
    pushIssue(
      warnings,
      "slug",
      "App slug is missing.",
      "The server normalized it from the app name.",
    );
  } else {
    normalized.slug = normalizeSlug(normalized.slug);
  }

  if (typeof normalized.appId !== "string" || normalized.appId.trim().length === 0) {
    normalized.appId = `app-${normalized.slug}`;
  }

  if (typeof normalized.name !== "string" || normalized.name.trim().length === 0) {
    normalized.name = "Untitled App";
    pushIssue(
      errors,
      "name",
      "App name is required.",
      "Provide a non-empty name for the application.",
    );
  }

  if (!isObject(normalized.theme)) {
    normalized.theme = { mode: "light", primaryColor: "#0f766e" };
    pushIssue(
      warnings,
      "theme",
      "App theme is missing.",
      "The server normalized it to the default light theme.",
    );
  }

  if (!isObject(normalized.layoutShell)) {
    normalized.layoutShell = {
      type: "sidebarShell",
      navigationStyle: "sidebar",
    };
    pushIssue(
      warnings,
      "layoutShell",
      "App layout shell is missing.",
      "The server normalized it to the default sidebar shell.",
    );
  }

  if (!Array.isArray(normalized.pages)) {
    normalized.pages = [];
    pushIssue(
      warnings,
      "pages",
      "App pages are missing.",
      "The server normalized pages to an empty array.",
    );
  }

  if (!Array.isArray(normalized.routes)) {
    normalized.routes = [];
    pushIssue(
      warnings,
      "routes",
      "App routes are missing.",
      "The server normalized routes to an empty array.",
    );
  }

  if (!Array.isArray(normalized.navigation)) {
    normalized.navigation = [];
    pushIssue(
      warnings,
      "navigation",
      "App navigation is missing.",
      "The server normalized navigation to an empty array.",
    );
  }

  if (!Array.isArray(normalized.buildProfiles)) {
    normalized.buildProfiles = defaultBuildProfiles();
    pushIssue(
      warnings,
      "buildProfiles",
      "Build profiles are missing.",
      "The server normalized buildProfiles to default debug targets.",
    );
  }

  const pages = normalized.pages as unknown[];
  const pageSlugs = new Set<string>();
  pages.forEach((page, index) => {
    if (!isObject(page)) {
      pushIssue(errors, `pages[${index}]`, "Each page entry must be an object.");
      return;
    }

    if (typeof page.slug !== "string" || page.slug.trim().length === 0) {
      pushIssue(errors, `pages[${index}].slug`, "Page entry slug is required.");
      return;
    }
    const normalizedPageSlug = normalizeSlug(page.slug);
    page.slug = normalizedPageSlug;
    pageSlugs.add(normalizedPageSlug);

    if (typeof page.pageUri !== "string" || page.pageUri.trim().length === 0) {
      pushIssue(
        errors,
        `pages[${index}].pageUri`,
        "Page entry pageUri is required.",
      );
    }
  });

  const routes = normalized.routes as unknown[];
  routes.forEach((route, index) => {
    if (!isObject(route)) {
      pushIssue(errors, `routes[${index}]`, "Each route entry must be an object.");
      return;
    }
    if (typeof route.path !== "string" || route.path.trim().length === 0) {
      pushIssue(errors, `routes[${index}].path`, "Route path is required.");
    } else if (!route.path.startsWith("/")) {
      pushIssue(
        errors,
        `routes[${index}].path`,
        "Route path must start with '/'.",
      );
    }

    if (typeof route.pageSlug !== "string" || route.pageSlug.trim().length === 0) {
      pushIssue(errors, `routes[${index}].pageSlug`, "Route pageSlug is required.");
      return;
    }
    const normalizedRoutePageSlug = normalizeSlug(route.pageSlug);
    route.pageSlug = normalizedRoutePageSlug;
    if (!pageSlugs.has(normalizedRoutePageSlug)) {
      pushIssue(
        warnings,
        `routes[${index}].pageSlug`,
        `Route references missing page "${normalizedRoutePageSlug}".`,
        "Add the page to the pages list or update the route reference.",
      );
    }
  });

  if (
    typeof normalized.homePage !== "string"
    || normalized.homePage.trim().length === 0
  ) {
    const fallback = (normalized.pages as Array<Record<string, unknown>>)[0]?.slug;
    if (typeof fallback === "string" && fallback.length > 0) {
      normalized.homePage = fallback;
      pushIssue(
        warnings,
        "homePage",
        "App homePage is missing.",
        "The server normalized it to the first page slug.",
      );
    }
  } else {
    normalized.homePage = normalizeSlug(normalized.homePage);
  }

  if (!isObject(normalized.auth)) {
    normalized.auth = { required: false };
  }
  if (!isObject(normalized.globalState)) {
    normalized.globalState = { initial: {} };
  }
  if (!Array.isArray(normalized.dataSources)) {
    normalized.dataSources = [];
  }

  return {
    valid: errors.length === 0,
    errors,
    warnings,
    normalizedSchema: normalized,
  };
}
