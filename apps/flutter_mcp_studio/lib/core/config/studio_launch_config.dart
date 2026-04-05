const String _defaultRuntimeBaseUrl = String.fromEnvironment(
  'MCP_UI_RUNTIME_BASE_URL',
  defaultValue: '',
);

class StudioLaunchConfig {
  const StudioLaunchConfig({this.runtimeBaseUrl});

  final String? runtimeBaseUrl;

  factory StudioLaunchConfig.fromEnvironment() {
    final query = Uri.base.queryParameters;
    return StudioLaunchConfig(
      runtimeBaseUrl: _normalizeOptionalUrl(
        _firstNonEmpty(
          query['runtime'],
          query['runtimeBaseUrl'],
          _defaultRuntimeBaseUrl,
        ),
      ),
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

String? _normalizeOptionalUrl(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  if (trimmed.endsWith('/')) {
    return trimmed.substring(0, trimmed.length - 1);
  }
  return trimmed;
}
