# Flutter MCP Configurable UI Studio Architecture

## Goals

- Render a configurable interactive page from JSON DSL through Flutter.
- Allow both humans and AI to mutate the same page definition.
- Persist curated versions into self-hosted storage and expose stable MCP resource URIs.
- Reuse one JSON definition across Flutter Web, embedded WebView shells, and native Flutter builds.

## Runtime Flow

1. Flutter loads a page definition from local cache or the MCP UI server.
2. `flutter_mcp_ui_runtime` renders the JSON DSL into a live page.
3. Human edits update the in-memory JSON and runtime state.
4. The "固化" action posts the current JSON back to the server.
5. The server creates a new immutable version and updates the stable resource URI.
6. AI clients can later request the stable resource or specific version through MCP tools/resources.

## Major Modules

- `apps/flutter_mcp_studio`
  - Main configurable Flutter UI studio.
  - Uses `flutter_mcp_ui_runtime` for rendering.
  - Uses `flutter_mcp` to prepare MCP client integration for later tool/resource calls.
- `server/mcp-ui-server`
  - Self-hosted MCP server plus HTTP API.
  - Default persistence is SQLite-based KV.
  - Optional Valkey adapter is available via environment variables.
- `apps/electron_shell`
  - Desktop shell that loads the Flutter Web build in a WebView.
- `apps/android_webview_shell`
  - Minimal Android native container that loads the Flutter Web build.

## Storage Strategy

- Default: SQLite-based KV for zero-dependency local demo.
- Optional: Valkey for shared multi-instance deployments.
- Each save creates an immutable version such as `v20260401-1`.
- Stable resource URI keeps pointing at the latest curated version.

## Resource URI Convention

- Stable page: `mcpui://pages/<slug>/stable`
- Immutable page version: `mcpui://pages/<slug>/versions/<version>`

## Extensibility

- Register Ant Design-like Flutter widgets under custom runtime types.
- Add new MCP tools without changing the Flutter renderer contract.
- Swap persistence implementation by implementing the same page store interface.
