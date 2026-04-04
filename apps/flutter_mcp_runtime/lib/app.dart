import 'package:flutter/material.dart';

import 'core/config/runtime_launch_config.dart';
import 'features/runtime/runtime_home_page.dart';

class FlutterMcpRuntimeApp extends StatelessWidget {
  const FlutterMcpRuntimeApp({super.key, required this.config});

  final RuntimeLaunchConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter MCP Runtime',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F3EF),
        useMaterial3: true,
      ),
      home: RuntimeHomePage(config: config),
    );
  }
}
