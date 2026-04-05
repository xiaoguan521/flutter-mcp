const String kDefaultServerUrl = String.fromEnvironment(
  'MCP_UI_SERVER_URL',
  defaultValue: 'http://127.0.0.1:8787',
);

const String _defaultPageSlug = String.fromEnvironment(
  'MCP_UI_PAGE_SLUG',
  defaultValue: '',
);

const String _defaultPageVersion = String.fromEnvironment(
  'MCP_UI_PAGE_VERSION',
  defaultValue: '',
);

const String _defaultPageUri = String.fromEnvironment(
  'MCP_UI_PAGE_URI',
  defaultValue: '',
);

const String _defaultAppSlug = String.fromEnvironment(
  'MCP_UI_APP_SLUG',
  defaultValue: '',
);

const String _defaultAppVersion = String.fromEnvironment(
  'MCP_UI_APP_VERSION',
  defaultValue: '',
);

const String _defaultAppUri = String.fromEnvironment(
  'MCP_UI_APP_URI',
  defaultValue: '',
);

const String _defaultAppRoute = String.fromEnvironment(
  'MCP_UI_APP_ROUTE',
  defaultValue: '',
);

class RuntimeLaunchConfig {
  const RuntimeLaunchConfig({
    required this.serverUrl,
    this.appSlug,
    this.appVersion,
    this.appUri,
    this.appRoute,
    this.pageSlug,
    this.pageVersion,
    this.pageUri,
  });

  final String serverUrl;
  final String? appSlug;
  final String? appVersion;
  final String? appUri;
  final String? appRoute;
  final String? pageSlug;
  final String? pageVersion;
  final String? pageUri;

  factory RuntimeLaunchConfig.fromEnvironment() {
    final query = Uri.base.queryParameters;
    final serverUrl = _normalizeBaseUrl(
      _firstNonEmpty(query['server'], query['baseUrl'], kDefaultServerUrl) ??
          kDefaultServerUrl,
    );

    return RuntimeLaunchConfig(
      serverUrl: serverUrl,
      appSlug: _firstNonEmpty(query['appSlug'], query['app'], _defaultAppSlug),
      appVersion: _firstNonEmpty(
        query['appVersion'],
        query['app_ver'],
        _defaultAppVersion,
      ),
      appUri: _firstNonEmpty(query['appUri'], query['app_uri'], _defaultAppUri),
      appRoute: _firstNonEmpty(
        query['route'],
        query['appRoute'],
        _defaultAppRoute,
      ),
      pageSlug: _firstNonEmpty(
        query['slug'],
        query['pageSlug'],
        _defaultPageSlug,
      ),
      pageVersion: _firstNonEmpty(
        query['version'],
        query['pageVersion'],
        _defaultPageVersion,
      ),
      pageUri: _firstNonEmpty(query['uri'], query['pageUri'], _defaultPageUri),
    );
  }
}

String? _firstNonEmpty(String? first, String? second, String? third) {
  for (final candidate in <String?>[first, second, third]) {
    final normalized = candidate?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
  }
  return null;
}

String _normalizeBaseUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.endsWith('/')) {
    return trimmed.substring(0, trimmed.length - 1);
  }
  return trimmed;
}
