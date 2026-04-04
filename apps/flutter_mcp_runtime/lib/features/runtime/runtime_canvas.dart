import 'package:flutter/material.dart';
import 'package:flutter_mcp_ui_runtime/flutter_mcp_ui_runtime.dart';

import '../../widgets/antd_widget_factories.dart';

class RuntimeCanvas extends StatefulWidget {
  const RuntimeCanvas({
    super.key,
    required this.definition,
    required this.revision,
    required this.onToolCall,
  });

  final Map<String, dynamic> definition;
  final int revision;
  final Future<Map<String, dynamic>> Function(
    String toolName,
    Map<String, dynamic> params,
  )
  onToolCall;

  @override
  State<RuntimeCanvas> createState() => _RuntimeCanvasState();
}

class _RuntimeCanvasState extends State<RuntimeCanvas> {
  MCPUIRuntime? _runtime;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void didUpdateWidget(covariant RuntimeCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision) {
      _boot();
    }
  }

  @override
  void dispose() {
    final runtime = _runtime;
    _runtime = null;
    if (runtime != null) {
      runtime.destroy();
    }
    super.dispose();
  }

  Future<void> _boot() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final previous = _runtime;
    if (previous != null) {
      await previous.destroy();
    }

    try {
      final runtime = MCPUIRuntime(enableDebugMode: false);
      await runtime.initialize(widget.definition);

      final engine = runtime.engine;
      if (engine == null) {
        throw StateError('Runtime engine was not created');
      }

      registerAntdWidgets(engine.widgetRegistry);

      runtime.registerToolExecutor('persistPage', (dynamic params) {
        return widget.onToolCall(
          'persistPage',
          Map<String, dynamic>.from(
            (params as Map?) ?? const <String, dynamic>{},
          ),
        );
      });

      runtime.registerToolExecutor('default', (
        String toolName,
        dynamic params,
      ) {
        return widget.onToolCall(
          toolName,
          Map<String, dynamic>.from(
            (params as Map?) ?? const <String, dynamic>{},
          ),
        );
      });

      if (!mounted) {
        await runtime.destroy();
        return;
      }

      setState(() {
        _runtime = runtime;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Runtime 初始化失败：$_error',
            style: const TextStyle(color: Color(0xFFB91C1C)),
          ),
        ),
      );
    }

    final runtime = _runtime;
    if (runtime == null) {
      return const SizedBox.shrink();
    }

    return runtime.buildUI();
  }
}
