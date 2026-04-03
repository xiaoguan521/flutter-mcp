import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'apps/studio_home_page.dart';
import 'core/services/mcp_bridge_service.dart';
import 'core/services/page_repository.dart';
import 'features/editor/studio_controller.dart';
import 'features/persistence/local_draft_store.dart';

class FlutterMcpStudioApp extends StatelessWidget {
  const FlutterMcpStudioApp({
    super.key,
    required this.draftStore,
  });

  final LocalDraftStore draftStore;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StudioController>(
      create: (_) => StudioController(
        repository: PageRepository(),
        draftStore: draftStore,
        mcpBridgeService: McpBridgeService(),
      )..bootstrap(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter MCP Studio',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F766E),
          ),
          scaffoldBackgroundColor: const Color(0xFFF4F1EA),
          useMaterial3: true,
        ),
        home: const StudioHomePage(),
      ),
    );
  }
}
