const PAGE_URI_PATTERN =
  /^mcpui:\/\/pages\/(?<slug>[a-z0-9-]+)\/(?<scope>stable|versions\/[A-Za-z0-9._-]+)$/;
const APP_URI_PATTERN =
  /^mcpui:\/\/apps\/(?<slug>[a-z0-9-]+)\/(?<scope>stable|versions\/[A-Za-z0-9._-]+)$/;

export function normalizeSlug(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .replace(/-{2,}/g, "-");
}

export function buildStableUri(slug: string): string {
  return `mcpui://pages/${normalizeSlug(slug)}/stable`;
}

export function buildVersionUri(slug: string, version: string): string {
  return `mcpui://pages/${normalizeSlug(slug)}/versions/${version}`;
}

export function buildAppStableUri(slug: string): string {
  return `mcpui://apps/${normalizeSlug(slug)}/stable`;
}

export function buildAppVersionUri(slug: string, version: string): string {
  return `mcpui://apps/${normalizeSlug(slug)}/versions/${version}`;
}

export function buildVersionId(date = new Date()): string {
  const iso = date.toISOString().replace(/[-:.TZ]/g, "");
  return `v${iso.slice(0, 14)}-${iso.slice(14, 17)}`;
}

export function parseResourceUri(uri: string):
  | {
      kind: "page" | "app";
      slug: string;
      version?: string;
      isStable: boolean;
    }
  | null {
  const pageMatch = PAGE_URI_PATTERN.exec(uri);
  const appMatch = APP_URI_PATTERN.exec(uri);
  const match = pageMatch ?? appMatch;
  if (!match?.groups) {
    return null;
  }

  const kind = pageMatch ? "page" : "app";
  const slug = match.groups.slug;
  const scope = match.groups.scope;
  if (scope === "stable") {
    return {
      kind,
      slug,
      isStable: true,
    };
  }

  return {
    kind,
    slug,
    version: scope.replace("versions/", ""),
    isStable: false,
  };
}
