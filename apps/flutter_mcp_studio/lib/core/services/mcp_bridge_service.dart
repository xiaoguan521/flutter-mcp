import 'package:flutter_mcp/flutter_mcp.dart';

import 'page_repository.dart';

class McpBridgeService {
  bool _initialized = false;
  String? _clientId;

  String? get clientId => _clientId;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await FlutterMCP.instance.init(
      MCPConfig(
        appName: 'Flutter MCP Studio',
        appVersion: '0.1.0',
        autoStart: false,
        lifecycleManaged: false,
        secure: false,
        useBackgroundService: false,
        useNotification: false,
        useTray: false,
      ),
    );
    _initialized = true;
  }

  Future<bool> ensureConnected({String? baseUrl}) async {
    await initialize();
    if (_clientId != null) {
      return true;
    }

    try {
      final resolvedBaseUrl = baseUrl ?? kDefaultServerUrl;
      final config = MCPClientConfig(
        name: 'studio-streamable-http',
        version: '0.1.0',
        transportType: 'streamablehttp',
        serverUrl: resolvedBaseUrl,
        endpoint: '/mcp',
      );

      _clientId = await FlutterMCP.instance.createClient(
        name: config.name,
        version: config.version,
        serverUrl: resolvedBaseUrl,
        config: config,
      );

      await FlutterMCP.instance.connectClient(_clientId!);
      return true;
    } catch (_) {
      _clientId = null;
      return false;
    }
  }
}

