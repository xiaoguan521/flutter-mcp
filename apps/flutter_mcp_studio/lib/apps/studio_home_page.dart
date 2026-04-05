import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/models/page_models.dart';
import '../features/editor/studio_controller.dart';
import '../features/runtime/runtime_canvas.dart';

class StudioHomePage extends StatefulWidget {
  const StudioHomePage({
    super.key,
    this.runtimeBaseUrl,
  });

  final String? runtimeBaseUrl;

  @override
  State<StudioHomePage> createState() => _StudioHomePageState();
}

class _StudioHomePageState extends State<StudioHomePage> {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _appSourceController = TextEditingController();
  final TextEditingController _appPromptController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _instructionController = TextEditingController();
  final TextEditingController _appNameController = TextEditingController();
  final TextEditingController _appDescriptionController =
      TextEditingController();
  final TextEditingController _appEditNameController = TextEditingController();
  final TextEditingController _appEditSlugController = TextEditingController();
  final TextEditingController _appEditDescriptionController =
      TextEditingController();
  final TextEditingController _appPrimaryColorController =
      TextEditingController();
  String _selectedPageType = 'dashboard';
  String _selectedNavigationStyle = 'sidebar';
  String? _selectedAndroidProfileId;
  String? _selectedWebProfileId;
  int _lastSourceRevision = -1;
  int _lastAppSourceRevision = -1;
  final Set<String> _selectedAppPageSlugs = <String>{};

  @override
  void dispose() {
    _sourceController.dispose();
    _appSourceController.dispose();
    _appPromptController.dispose();
    _promptController.dispose();
    _instructionController.dispose();
    _appNameController.dispose();
    _appDescriptionController.dispose();
    _appEditNameController.dispose();
    _appEditSlugController.dispose();
    _appEditDescriptionController.dispose();
    _appPrimaryColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudioController>(
      builder: (context, controller, _) {
        if (_lastSourceRevision != controller.sourceRevision) {
          _lastSourceRevision = controller.sourceRevision;
          _sourceController.value = TextEditingValue(
            text: controller.prettySource,
            selection: TextSelection.collapsed(
              offset: controller.prettySource.length,
            ),
          );
        }
        if (_lastAppSourceRevision != controller.appSourceRevision) {
          _lastAppSourceRevision = controller.appSourceRevision;
          _appSourceController.value = TextEditingValue(
            text: controller.prettyAppSource,
            selection: TextSelection.collapsed(
              offset: controller.prettyAppSource.length,
            ),
          );
          _appEditNameController.text =
              controller.currentAppDocument?.name ?? '';
          _appEditSlugController.text =
              controller.currentAppDocument?.slug ?? '';
          _appEditDescriptionController.text =
              controller.currentAppDocument?.description ?? '';
          final theme = _asMap(controller.currentAppDocument?.schema['theme']);
          _appPrimaryColorController.text =
              theme['primaryColor']?.toString() ?? '#0F766E';
          _selectedAndroidProfileId = _resolveProfileSelection(
            current: _selectedAndroidProfileId,
            profiles: controller.androidBuildProfiles,
          );
          _selectedWebProfileId = _resolveProfileSelection(
            current: _selectedWebProfileId,
            profiles: controller.webBuildProfiles,
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF4F1EA),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF4F1EA),
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Flutter MCP Studio',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  controller.statusMessage,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => controller.reconnectMcp(),
                child: Text(
                  controller.isMcpConnected ? 'MCP 已连接' : '连接 MCP',
                  style: TextStyle(
                    color: controller.isMcpConnected
                        ? const Color(0xFF0F766E)
                        : const Color(0xFF1D4ED8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed:
                    controller.currentDocument == null || controller.isSaving
                        ? null
                        : () => controller.persistCurrentPage(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                ),
                child: controller.isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('固化当前页'),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                if (controller.error != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      controller.error!,
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 1100) {
                        return _buildCompactLayout(controller);
                      }
                      return _buildWideLayout(controller);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWideLayout(StudioController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 300,
            child: _buildPageRail(controller),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildPreviewPanel(controller),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 380,
            child: _buildEditorPanel(controller),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLayout(StudioController controller) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: <Widget>[
          const TabBar(
            tabs: <Tab>[
              Tab(text: '页面'),
              Tab(text: '预览'),
              Tab(text: '编辑'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildPageRail(controller),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildPreviewPanel(controller),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildEditorPanel(controller),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageRail(StudioController controller) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text(
                '页面与应用',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => controller.refreshWorkspace(),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          if (controller.draftUpdatedAt != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE68A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '本地草稿：${controller.draftUpdatedAt}',
                style: const TextStyle(
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const Text(
            '页面列表',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: <Widget>[
                ...controller.pages.map(
                  (page) => Card(
                    elevation: 0,
                    color: controller.selectedSlug == page.slug
                        ? const Color(0xFFE0F2FE)
                        : const Color(0xFFF8FAFC),
                    child: ListTile(
                      title: Text(page.title),
                      subtitle: Text(page.description ?? page.slug),
                      trailing: page.isBundled
                          ? const Icon(Icons.inventory_2_outlined, size: 18)
                          : const Icon(Icons.cloud_done_outlined, size: 18),
                      onTap: () => controller.loadPage(page.slug),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '应用列表',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                if (controller.apps.isEmpty)
                  Card(
                    elevation: 0,
                    color: const Color(0xFFF8FAFC),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        controller.isUsingBundledFallback
                            ? '服务端离线时不可加载应用'
                            : '还没有已保存的应用',
                      ),
                      subtitle: const Text('可在右侧创建一个应用骨架'),
                    ),
                  ),
                ...controller.apps.map(
                  (app) => Card(
                    elevation: 0,
                    color: controller.selectedAppSlug == app.slug
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFF8FAFC),
                    child: ListTile(
                      title: Text(app.name),
                      subtitle: Text(app.description ?? app.slug),
                      trailing:
                          const Icon(Icons.account_tree_outlined, size: 18),
                      onTap: controller.isUsingBundledFallback
                          ? null
                          : () => controller.loadApp(app.slug),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '应用版本',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                ...controller.appVersions.map(
                  (version) => Card(
                    elevation: 0,
                    color: version.version == controller.selectedAppVersion
                        ? const Color(0xFFFFF7ED)
                        : const Color(0xFFF8FAFC),
                    child: ListTile(
                      dense: true,
                      title: Text(version.version),
                      subtitle: Text(version.note ?? version.createdAt),
                      trailing: version.isStable
                          ? const Icon(Icons.push_pin_outlined, size: 18)
                          : const Icon(Icons.history_rounded, size: 18),
                      onTap: controller.isUsingBundledFallback
                          ? null
                          : () => controller.loadApp(
                                version.slug,
                                version: version.version,
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '版本记录',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                ...controller.versions.map(
                  (version) => Card(
                    elevation: 0,
                    color: version.version == controller.selectedVersion
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFF8FAFC),
                    child: ListTile(
                      dense: true,
                      title: Text(version.version),
                      subtitle: Text(version.note ?? version.createdAt),
                      trailing: version.isStable
                          ? const Icon(Icons.push_pin_outlined, size: 18)
                          : const Icon(Icons.history_rounded, size: 18),
                      onTap: controller.isUsingBundledFallback
                          ? null
                          : () => controller.loadPage(
                                version.slug,
                                version: version.version,
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPanel(StudioController controller) {
    final document = controller.currentDocument;
    final appDocument = controller.currentAppDocument;
    final appRoutes = controller.currentAppRoutes;
    final generation = controller.lastGeneration;
    final explanation = controller.lastExplanation;
    final update = controller.lastInstructionUpdate;
    final validation = controller.validationResult;
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            document?.title ?? '未选择页面',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            appDocument != null
                ? (appDocument.description ?? '当前正在预览应用骨架与页面路由。')
                : (document?.description ?? '从左侧选择一个样例页面开始编辑。'),
            style: const TextStyle(
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          if (appDocument != null)
            _buildAppSummary(
              appDocument,
              controller.lastAppWarnings,
              controller.activeAppRoute,
              appRoutes,
              controller,
            ),
          if (document?.versionUri != null && document!.versionUri!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SelectableText(
                document.versionUri!,
                style: const TextStyle(
                  color: Color(0xFF0F766E),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ..._buildPageRuntimeLaunchSection(controller, document),
          // -- AI 生成摘要 --
          if (generation != null) _buildGenerationSummary(generation),
          if (explanation != null) _buildExplanationSummary(explanation),
          if (update != null) _buildInstructionSummary(update),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAF9),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: _buildPreviewSurface(
                controller,
                document,
                appDocument,
                appRoutes,
              ),
            ),
          ),
          // -- 校验结果展示 --
          if (validation != null) _buildValidationPanel(validation),
        ],
      ),
    );
  }

  Widget _buildAppSummary(
    AppDocumentModel app,
    List<String> warnings,
    String? activeRoute,
    List<Map<String, dynamic>> routes,
    StudioController controller,
  ) {
    final navigation =
        (app.schema['navigation'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
    final layoutShellRaw = app.schema['layoutShell'];
    final layoutShell = layoutShellRaw is Map<String, dynamic>
        ? layoutShellRaw
        : layoutShellRaw is Map
            ? Map<String, dynamic>.from(layoutShellRaw)
            : null;
    final navigationStyle = layoutShell?['navigationStyle']?.toString() ?? '-';
    final homePage = app.schema['homePage']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.account_tree_outlined,
                  size: 16, color: Color(0xFFEA580C)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '当前应用 · ${app.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9A3412),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '导航：$navigationStyle  ·  首页：$homePage',
            style: const TextStyle(
              color: Color(0xFF9A3412),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (app.versionUri != null && app.versionUri!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SelectableText(
                app.versionUri!,
                style: const TextStyle(
                  color: Color(0xFFC2410C),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ..._buildAppRuntimeLaunchSection(
            controller,
            app,
            activeRoute: activeRoute,
          ),
          if (routes.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              '路由',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF9A3412),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: routes.take(6).map((route) {
                final path = route['path']?.toString() ?? '-';
                final selected = path == activeRoute;
                return ActionChip(
                  backgroundColor: selected
                      ? const Color(0xFFF97316)
                      : const Color(0xFFFFEDD5),
                  label: Text(
                    '${route['title'] ?? route['pageSlug'] ?? '-'} · $path',
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF9A3412),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => controller.openAppRoute(path),
                );
              }).toList(),
            ),
          ],
          if (navigation.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              '导航节点',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF9A3412),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: navigation.take(6).map((item) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDD5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item['label']?.toString() ??
                        item['route']?.toString() ??
                        '-',
                    style: const TextStyle(
                      color: Color(0xFF9A3412),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...warnings.map(
              (warning) => Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  warning,
                  style:
                      const TextStyle(color: Color(0xFF92400E), fontSize: 11),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewSurface(
    StudioController controller,
    PageDocumentModel? document,
    AppDocumentModel? appDocument,
    List<Map<String, dynamic>> appRoutes,
  ) {
    if (document == null) {
      return const Center(
        child: Text('暂无页面'),
      );
    }

    if (appDocument == null) {
      return RuntimeCanvas(
        definition: document.definition,
        revision: controller.runtimeRevision,
        onToolCall: controller.invokeRuntimeTool,
      );
    }

    final layoutShellRaw = appDocument.schema['layoutShell'];
    final layoutShell = layoutShellRaw is Map<String, dynamic>
        ? layoutShellRaw
        : layoutShellRaw is Map
            ? Map<String, dynamic>.from(layoutShellRaw)
            : <String, dynamic>{};
    final theme = _asMap(appDocument.schema['theme']);
    final navigationStyle =
        layoutShell['navigationStyle']?.toString() ?? 'sidebar';
    final isDark = theme['mode']?.toString() == 'dark';
    final primaryColor = _parseHexColor(
      theme['primaryColor']?.toString(),
      fallback: const Color(0xFF0F766E),
    );
    final shellBackground =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFCF7);
    final shellBorder =
        isDark ? const Color(0xFF334155) : const Color(0xFFF3E8D8);

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Container(
        decoration: BoxDecoration(
          color: shellBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: shellBorder),
        ),
        child: navigationStyle == 'sidebar'
            ? Row(
                children: <Widget>[
                  SizedBox(
                    width: 220,
                    child: _buildAppNavigationRail(
                      controller,
                      appDocument,
                      appRoutes,
                      primaryColor: primaryColor,
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildAppPageViewport(
                      controller,
                      document,
                      primaryColor: primaryColor,
                      isDark: isDark,
                    ),
                  ),
                ],
              )
            : Column(
                children: <Widget>[
                  _buildAppNavigationHeader(
                    controller,
                    appDocument,
                    appRoutes,
                    compact: navigationStyle == 'tabs',
                    primaryColor: primaryColor,
                    isDark: isDark,
                  ),
                  Expanded(
                    child: _buildAppPageViewport(
                      controller,
                      document,
                      primaryColor: primaryColor,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAppNavigationRail(
    StudioController controller,
    AppDocumentModel appDocument,
    List<Map<String, dynamic>> appRoutes, {
    required Color primaryColor,
    required bool isDark,
  }) {
    final railBackground =
        isDark ? const Color(0xFF111827) : const Color(0xFFF6EDE1);
    final railText = isDark ? const Color(0xFFE5E7EB) : const Color(0xFF7C2D12);
    final railMuted =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF9A3412);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: railBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          bottomLeft: Radius.circular(18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            appDocument.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: railText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            appDocument.description ?? 'Sidebar shell',
            style: TextStyle(
              color: railMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ...appRoutes.map((route) {
            final path = route['path']?.toString() ?? '';
            final selected = path == controller.activeAppRoute;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => controller.openAppRoute(path),
                child: Ink(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? primaryColor
                        : (isDark
                            ? const Color(0xFF1F2937)
                            : const Color(0xFFFFF7ED)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 14,
                        color: selected ? Colors.white : railMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          route['title']?.toString() ??
                              route['pageSlug']?.toString() ??
                              path,
                          style: TextStyle(
                            color: selected ? Colors.white : railText,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAppNavigationHeader(
    StudioController controller,
    AppDocumentModel appDocument,
    List<Map<String, dynamic>> appRoutes, {
    required bool compact,
    required Color primaryColor,
    required bool isDark,
  }) {
    final headerBackground =
        isDark ? const Color(0xFF111827) : const Color(0xFFF6EDE1);
    final headerText =
        isDark ? const Color(0xFFE5E7EB) : const Color(0xFF7C2D12);
    final headerMuted =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF9A3412);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: headerBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            appDocument.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: headerText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            appDocument.description ??
                (compact ? 'Tabs shell' : 'Topbar shell'),
            style: TextStyle(
              color: headerMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: appRoutes.map((route) {
              final path = route['path']?.toString() ?? '';
              final selected = path == controller.activeAppRoute;
              return ChoiceChip(
                selected: selected,
                selectedColor: primaryColor,
                backgroundColor:
                    isDark ? const Color(0xFF1F2937) : const Color(0xFFFFF7ED),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : headerText,
                  fontWeight: FontWeight.w600,
                ),
                label: Text(
                  route['title']?.toString() ??
                      route['pageSlug']?.toString() ??
                      path,
                ),
                onSelected: (_) => controller.openAppRoute(path),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppPageViewport(
    StudioController controller,
    PageDocumentModel document, {
    required Color primaryColor,
    required bool isDark,
  }) {
    final titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final mutedColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            document.title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            controller.activeAppRoute == null
                ? '页面预览'
                : '当前路由：${controller.activeAppRoute}',
            style: TextStyle(
              color: mutedColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0B1220)
                      : const Color(0xFFFFFFFF),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.24),
                  ),
                ),
                child: RuntimeCanvas(
                  definition: document.definition,
                  revision: controller.runtimeRevision,
                  onToolCall: controller.invokeRuntimeTool,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionSummary(PageUpdateResultModel update) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: const <Widget>[
              Icon(Icons.auto_fix_high_rounded,
                  size: 16, color: Color(0xFF2563EB)),
              SizedBox(width: 6),
              Text(
                'AI 二次修改',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D4ED8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            update.summary,
            style: const TextStyle(
                color: Color(0xFF1E3A8A), fontSize: 12, height: 1.5),
          ),
          if (update.appliedChanges.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              '已应用修改',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D4ED8),
                  fontSize: 12),
            ),
            const SizedBox(height: 4),
            ...update.appliedChanges.map(
              (item) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text('· $item',
                    style: const TextStyle(
                        color: Color(0xFF1E3A8A), fontSize: 11, height: 1.4)),
              ),
            ),
          ],
          if (update.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...update.warnings.map(
              (warning) => Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  warning,
                  style:
                      const TextStyle(color: Color(0xFF92400E), fontSize: 11),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExplanationSummary(PageExplanationResultModel explanation) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: const <Widget>[
              Icon(Icons.tips_and_updates_outlined,
                  size: 16, color: Color(0xFFD97706)),
              SizedBox(width: 6),
              Text(
                '页面解释',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF92400E),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            explanation.summary,
            style: const TextStyle(
              color: Color(0xFF78350F),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '页面类型：${explanation.pageType}',
            style: const TextStyle(
              color: Color(0xFF92400E),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (explanation.structure.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              '结构概览',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF92400E),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            ...explanation.structure.take(6).map(
                  (item) => Text(
                    item,
                    style: const TextStyle(
                      color: Color(0xFF78350F),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
          ],
          if (explanation.actionSummary.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              '动作摘要',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF92400E),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            ...explanation.actionSummary.take(4).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '· $item',
                      style: const TextStyle(
                        color: Color(0xFF78350F),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenerationSummary(GeneratedPageResultModel generation) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.auto_awesome,
                  size: 16, color: Color(0xFF059669)),
              const SizedBox(width: 6),
              Text(
                'AI 生成 · ${generation.pageType}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF065F46),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            generation.summary,
            style: const TextStyle(
                color: Color(0xFF064E3B), fontSize: 12, height: 1.5),
          ),
          if (generation.assumptions.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'AI 假设',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF065F46),
                  fontSize: 12),
            ),
            const SizedBox(height: 4),
            ...generation.assumptions.map(
              (a) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text('· $a',
                    style: const TextStyle(
                        color: Color(0xFF064E3B), fontSize: 11, height: 1.4)),
              ),
            ),
          ],
          if (generation.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...generation.warnings.map(
              (w) => Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(w,
                    style: const TextStyle(
                        color: Color(0xFF92400E), fontSize: 11)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildValidationPanel(PageValidationResultModel validation) {
    if (validation.errors.isEmpty && validation.warnings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: const <Widget>[
            Icon(Icons.check_circle_outline,
                size: 16, color: Color(0xFF059669)),
            SizedBox(width: 6),
            Text(
              '页面结构校验通过',
              style: TextStyle(
                  color: Color(0xFF059669),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      constraints: const BoxConstraints(maxHeight: 160),
      decoration: BoxDecoration(
        color: validation.valid
            ? const Color(0xFFFFFBEB)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: validation.valid
              ? const Color(0xFFFDE68A)
              : const Color(0xFFFECACA),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(10),
        children: <Widget>[
          ...validation.errors.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.error_outline,
                      size: 14, color: Color(0xFFDC2626)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${e.path}: ${e.message}',
                          style: const TextStyle(
                              color: Color(0xFFB91C1C),
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                        if (e.suggestion != null)
                          Text(
                            e.suggestion!,
                            style: const TextStyle(
                                color: Color(0xFF92400E), fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...validation.warnings.map(
            (w) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.warning_amber_rounded,
                      size: 14, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${w.path}: ${w.message}',
                          style: const TextStyle(
                              color: Color(0xFF92400E),
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                        if (w.suggestion != null)
                          Text(
                            w.suggestion!,
                            style: const TextStyle(
                                color: Color(0xFF78716C), fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppValidationPanel(AppValidationResultModel validation) {
    if (validation.errors.isEmpty && validation.warnings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: const <Widget>[
            Icon(Icons.check_circle_outline,
                size: 16, color: Color(0xFF059669)),
            SizedBox(width: 6),
            Text(
              '应用 Schema 校验通过',
              style: TextStyle(
                color: Color(0xFF059669),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      constraints: const BoxConstraints(maxHeight: 160),
      decoration: BoxDecoration(
        color: validation.valid
            ? const Color(0xFFFFFBEB)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: validation.valid
              ? const Color(0xFFFDE68A)
              : const Color(0xFFFECACA),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(10),
        children: <Widget>[
          ...validation.errors.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                '${e.path}: ${e.message}',
                style: const TextStyle(
                  color: Color(0xFFB91C1C),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          ...validation.warnings.map(
            (w) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                '${w.path}: ${w.message}',
                style: const TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorPanel(StudioController controller) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!controller.isUsingBundledFallback) ...[
            _buildAppBuilderPanel(controller),
            if (controller.currentAppDocument != null) ...[
              const SizedBox(height: 16),
              _buildAppSchemaPanel(controller),
            ],
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
          ],
          // -- AI Prompt 面板 --
          if (controller.canUseAiTools) ...[
            _buildPromptPanel(controller),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
          ],
          const Text(
            '人工定制',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton(
                onPressed: controller.currentDocument == null
                    ? null
                    : () => controller.addBlock('kpi'),
                child: const Text('添加 KPI'),
              ),
              OutlinedButton(
                onPressed: controller.currentDocument == null
                    ? null
                    : () => controller.addBlock('table'),
                child: const Text('添加表格'),
              ),
              OutlinedButton(
                onPressed: controller.currentDocument == null
                    ? null
                    : () => controller.addBlock('toolbar'),
                child: const Text('添加操作条'),
              ),
              OutlinedButton(
                onPressed: controller.currentDocument == null
                    ? null
                    : () => controller.addBlock('note'),
                child: const Text('添加说明'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '拖拽排序',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 2,
            child: ReorderableListView.builder(
              itemCount: controller.contentBlocks.length,
              onReorder: (oldIndex, newIndex) {
                controller.moveBlock(oldIndex, newIndex);
              },
              buildDefaultDragHandles: false,
              itemBuilder: (context, index) {
                final block = controller.contentBlocks[index];
                return Card(
                  key:
                      ValueKey('${block['metaId'] ?? block['title'] ?? index}'),
                  elevation: 0,
                  color: const Color(0xFFF8FAFC),
                  child: ListTile(
                    title: Text(controller.describeBlock(block, index)),
                    subtitle: Text(block['type']?.toString() ?? ''),
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_indicator_rounded),
                    ),
                    trailing: IconButton(
                      onPressed: () => controller.removeBlock(index),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              const Text(
                'JSON DSL',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => controller.restoreDraft(),
                child: const Text('恢复草稿'),
              ),
              TextButton(
                onPressed: () => controller.clearDraft(),
                child: const Text('清空草稿'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _sourceController,
              expands: true,
              maxLines: null,
              minLines: null,
              style: const TextStyle(
                fontFamily: 'Courier New',
                fontSize: 13,
                height: 1.4,
                color: Color(0xFFE2E8F0),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                hintText: '在这里直接编辑页面 JSON DSL',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: controller.currentDocument == null
                  ? null
                  : () => controller.applySource(_sourceController.text),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
              ),
              child: const Text('应用 JSON 到预览'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBuilderPanel(StudioController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: const <Widget>[
            Icon(Icons.account_tree_outlined,
                size: 18, color: Color(0xFFEA580C)),
            SizedBox(width: 6),
            Text(
              '应用骨架',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _appPromptController,
          maxLines: 3,
          minLines: 2,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            hintText: '例如：生成一个订单管理后台，包含总览、订单列表、订单详情和设置页',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEA580C), width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 36,
          child: FilledButton.icon(
            onPressed: controller.isGeneratingApp
                ? null
                : () => controller.generateAppFromPrompt(
                      prompt: _appPromptController.text,
                      navigationStyle: _selectedNavigationStyle,
                    ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC2410C),
            ),
            icon: controller.isGeneratingApp
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome, size: 16),
            label: Text(
              controller.isGeneratingApp ? '生成中…' : 'AI 生成多页应用',
            ),
          ),
        ),
        if (controller.lastGeneratedApp != null) ...[
          const SizedBox(height: 10),
          _buildGeneratedAppSummary(controller.lastGeneratedApp!),
        ],
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        TextField(
          controller: _appNameController,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            hintText: '例如：销售运营后台',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEA580C), width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _appDescriptionController,
          maxLines: 2,
          minLines: 1,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            hintText: '说明这个应用包含哪些页面和导航目标',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEA580C), width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 10),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedNavigationStyle,
              isDense: true,
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem(value: 'sidebar', child: Text('Sidebar')),
                DropdownMenuItem(value: 'tabs', child: Text('Tabs')),
                DropdownMenuItem(value: 'topbar', child: Text('Topbar')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedNavigationStyle = value);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '包含页面',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        if (controller.pages.isEmpty)
          const Text(
            '当前还没有可编排的页面。',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.pages.map((page) {
              final selected = _selectedAppPageSlugs.contains(page.slug);
              return FilterChip(
                selected: selected,
                label: Text(page.title),
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _selectedAppPageSlugs.add(page.slug);
                    } else {
                      _selectedAppPageSlugs.remove(page.slug);
                    }
                  });
                },
              );
            }).toList(),
          ),
        const SizedBox(height: 8),
        Text(
          _selectedAppPageSlugs.isEmpty
              ? '未勾选时会默认包含当前所有页面。'
              : '已选择 ${_effectiveAppPageSlugs(controller).length} 个页面。',
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 36,
          child: FilledButton.icon(
            onPressed: controller.isCreatingApp || controller.pages.isEmpty
                ? null
                : () {
                    controller.createApp(
                      name: _appNameController.text,
                      description: _appDescriptionController.text,
                      pageSlugs: _effectiveAppPageSlugs(controller),
                      navigationStyle: _selectedNavigationStyle,
                    );
                  },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
            ),
            icon: controller.isCreatingApp
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.account_tree_outlined, size: 16),
            label: Text(controller.isCreatingApp ? '创建中…' : '生成应用骨架'),
          ),
        ),
      ],
    );
  }

  Widget _buildAppSchemaPanel(StudioController controller) {
    final document = controller.currentAppDocument;
    final validation = controller.appValidationResult;
    if (document == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.schema_outlined,
                size: 18, color: Color(0xFFB45309)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '应用 Schema · ${document.name}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            TextButton(
              onPressed: () => controller.validateCurrentApp(),
              child: const Text('校验'),
            ),
            FilledButton(
              onPressed: controller.isSaving
                  ? null
                  : () => controller.persistCurrentApp(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB45309),
              ),
              child: controller.isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('固化应用'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                      'android-profile-${_selectedAndroidProfileId ?? 'none'}',
                    ),
                    initialValue: _selectedAndroidProfileId,
                    decoration: _smallInputDecoration('Android Profile'),
                    items: controller.androidBuildProfiles
                        .map(
                          (profile) => DropdownMenuItem<String>(
                            value: profile['id']?.toString(),
                            child: Text(profile['id']?.toString() ?? 'android'),
                          ),
                        )
                        .toList(),
                    onChanged: controller.androidBuildProfiles.isEmpty
                        ? null
                        : (value) {
                            setState(() => _selectedAndroidProfileId = value);
                          },
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: controller.isBuildingApp
                        ? null
                        : () => controller.buildCurrentAppAndroidDebug(
                              profileId: _selectedAndroidProfileId,
                            ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                    ),
                    icon: controller.isBuildingApp
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.android_rounded, size: 16),
                    label: Text(
                      controller.isBuildingApp ? '构建中…' : '构建 Android Debug',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                      'web-profile-${_selectedWebProfileId ?? 'none'}',
                    ),
                    initialValue: _selectedWebProfileId,
                    decoration: _smallInputDecoration('Web Profile'),
                    items: controller.webBuildProfiles
                        .map(
                          (profile) => DropdownMenuItem<String>(
                            value: profile['id']?.toString(),
                            child: Text(profile['id']?.toString() ?? 'web'),
                          ),
                        )
                        .toList(),
                    onChanged: controller.webBuildProfiles.isEmpty
                        ? null
                        : (value) {
                            setState(() => _selectedWebProfileId = value);
                          },
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: controller.isBuildingWeb
                        ? null
                        : () => controller.buildCurrentAppWeb(
                              profileId: _selectedWebProfileId,
                            ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                    ),
                    icon: controller.isBuildingWeb
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.language_rounded, size: 16),
                    label: Text(
                      controller.isBuildingWeb ? '构建中…' : '构建 Web',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (controller.lastAndroidBuild != null) ...[
          const SizedBox(height: 10),
          _buildAndroidBuildResult(controller.lastAndroidBuild!),
        ],
        if (controller.lastWebBuild != null) ...[
          const SizedBox(height: 10),
          _buildWebBuildResult(controller.lastWebBuild!),
        ],
        const SizedBox(height: 10),
        _buildAppQuickEditor(controller, document),
        const SizedBox(height: 12),
        TextField(
          controller: _appSourceController,
          expands: false,
          maxLines: 12,
          minLines: 8,
          style: const TextStyle(
            fontFamily: 'Courier New',
            fontSize: 12,
            height: 1.4,
            color: Color(0xFFE2E8F0),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1C1917),
            hintText: '在这里直接编辑应用 Schema',
            hintStyle: const TextStyle(color: Color(0xFFA8A29E)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () =>
                controller.applyAppSource(_appSourceController.text),
            child: const Text('应用 Schema 到应用预览'),
          ),
        ),
        if (validation != null) _buildAppValidationPanel(validation),
      ],
    );
  }

  Widget _buildGeneratedAppSummary(GeneratedAppResultModel result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            result.summary,
            style: const TextStyle(
              color: Color(0xFF9A3412),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (result.generatedPages.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...result.generatedPages.map(
              (page) => Text(
                '${page.title} · ${page.pageType}',
                style: const TextStyle(
                  color: Color(0xFF7C2D12),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ),
          ],
          if (result.assumptions.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...result.assumptions.map(
              (item) => Text(
                '· $item',
                style: const TextStyle(
                  color: Color(0xFF9A3412),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAndroidBuildResult(AndroidBuildResultModel result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '最近一次 Android 构建',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF065F46),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '模式：${result.buildMode}  ·  平台：${result.targetPlatform}',
            style: const TextStyle(
              color: Color(0xFF065F46),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            result.artifactPath,
            style: const TextStyle(
              color: Color(0xFF0F766E),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (result.logSummary.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...result.logSummary.map(
              (line) => Text(
                line,
                style: const TextStyle(
                  color: Color(0xFF064E3B),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWebBuildResult(WebBuildResultModel result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '最近一次 Web 构建',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D4ED8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '模式：${result.buildMode}',
            style: const TextStyle(
              color: Color(0xFF1E3A8A),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            result.artifactPath,
            style: const TextStyle(
              color: Color(0xFF1D4ED8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (result.logSummary.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...result.logSummary.map(
              (line) => Text(
                line,
                style: const TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppQuickEditor(
    StudioController controller,
    AppDocumentModel document,
  ) {
    final layoutShell = _asMap(document.schema['layoutShell']);
    final theme = _asMap(document.schema['theme']);
    final navigationStyle =
        layoutShell['navigationStyle']?.toString() ?? 'sidebar';
    final homePage = document.schema['homePage']?.toString();
    final themeMode = theme['mode']?.toString() ?? 'light';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7D9C7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '快速编辑',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _appEditNameController,
            decoration: _smallInputDecoration('应用名称'),
            onSubmitted: (value) =>
                controller.updateCurrentAppMetadata(name: value),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _appEditSlugController,
            decoration: _smallInputDecoration('应用 slug'),
            onSubmitted: (value) =>
                controller.updateCurrentAppMetadata(slug: value),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _appEditDescriptionController,
            minLines: 2,
            maxLines: 3,
            decoration: _smallInputDecoration('应用描述'),
            onSubmitted: (value) =>
                controller.updateCurrentAppMetadata(description: value),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => controller.updateCurrentAppMetadata(
                name: _appEditNameController.text,
                slug: _appEditSlugController.text,
                description: _appEditDescriptionController.text,
              ),
              child: const Text('应用元数据'),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: navigationStyle,
                  decoration: _smallInputDecoration('导航样式'),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'sidebar', child: Text('Sidebar')),
                    DropdownMenuItem(value: 'tabs', child: Text('Tabs')),
                    DropdownMenuItem(value: 'topbar', child: Text('Topbar')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.updateCurrentAppMetadata(
                        navigationStyle: value,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: homePage != null &&
                          controller.pages.any((page) => page.slug == homePage)
                      ? homePage
                      : null,
                  decoration: _smallInputDecoration('首页页面'),
                  items: controller.pages
                      .map(
                        (page) => DropdownMenuItem<String>(
                          value: page.slug,
                          child: Text(page.title),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.updateCurrentAppMetadata(homePage: value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: themeMode,
                  decoration: _smallInputDecoration('主题模式'),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'light', child: Text('Light')),
                    DropdownMenuItem(value: 'dark', child: Text('Dark')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.updateCurrentAppTheme(mode: value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _appPrimaryColorController,
                  decoration: _smallInputDecoration('主色 (#RRGGBB)'),
                  onSubmitted: (value) =>
                      controller.updateCurrentAppTheme(primaryColor: value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => controller.updateCurrentAppTheme(
                mode: themeMode,
                primaryColor: _appPrimaryColorController.text,
              ),
              child: const Text('应用主题'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              const Text(
                '路由',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: controller.addCurrentAppRoute,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('添加路由'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (controller.currentAppRoutes.isEmpty)
            const Text(
              '当前还没有路由。',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            )
          else
            ...controller.currentAppRoutes.asMap().entries.map(
                  (entry) => _buildRouteEditorCard(
                    controller,
                    entry.key,
                    entry.value,
                  ),
                ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              const Text(
                '构建配置',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: controller.addCurrentBuildProfile,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('添加配置'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._buildProfileEditors(controller, document),
        ],
      ),
    );
  }

  Widget _buildRouteEditorCard(
    StudioController controller,
    int index,
    Map<String, dynamic> route,
  ) {
    final currentPageSlug = route['pageSlug']?.toString();
    final isHomePage =
        controller.currentAppDocument?.schema['homePage']?.toString() ==
            currentPageSlug;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                isHomePage ? 'Route ${index + 1} · Home' : 'Route ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: currentPageSlug == null || currentPageSlug.isEmpty
                    ? null
                    : () => controller.setCurrentAppHomePage(currentPageSlug),
                icon: Icon(
                  isHomePage ? Icons.home_filled : Icons.home_outlined,
                  size: 18,
                ),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: index == 0
                    ? null
                    : () => controller.moveCurrentAppRoute(index, index - 1),
                icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: index >= controller.currentAppRoutes.length - 1
                    ? null
                    : () => controller.moveCurrentAppRoute(index, index + 1),
                icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () => controller.removeCurrentAppRoute(index),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          DropdownButtonFormField<String>(
            initialValue: currentPageSlug != null &&
                    controller.pages.any((page) => page.slug == currentPageSlug)
                ? currentPageSlug
                : null,
            decoration: _smallInputDecoration('绑定页面'),
            items: controller.pages
                .map(
                  (page) => DropdownMenuItem<String>(
                    value: page.slug,
                    child: Text(page.title),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                controller.updateCurrentAppRoute(index, pageSlug: value);
              }
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('route-title-$index-${route['title']}'),
            initialValue: route['title']?.toString() ?? '',
            decoration: _smallInputDecoration('路由标题'),
            onFieldSubmitted: (value) =>
                controller.updateCurrentAppRoute(index, title: value),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('route-path-$index-${route['path']}'),
            initialValue: route['path']?.toString() ?? '',
            decoration: _smallInputDecoration('路由路径'),
            onFieldSubmitted: (value) =>
                controller.updateCurrentAppRoute(index, path: value),
          ),
        ],
      ),
    );
  }

  InputDecoration _smallInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFFFFFFF),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  String? _resolveProfileSelection({
    required String? current,
    required List<Map<String, dynamic>> profiles,
  }) {
    if (profiles.isEmpty) {
      return null;
    }
    if (current != null &&
        profiles.any((profile) => profile['id']?.toString() == current)) {
      return current;
    }
    return profiles.first['id']?.toString();
  }

  List<Widget> _buildProfileEditors(
    StudioController controller,
    AppDocumentModel document,
  ) {
    final profiles =
        (document.schema['buildProfiles'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
    if (profiles.isEmpty) {
      return const <Widget>[
        Text(
          '当前还没有构建配置。',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
      ];
    }

    return profiles.asMap().entries.map((entry) {
      final index = entry.key;
      final profile = entry.value;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'Profile ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => controller.removeCurrentBuildProfile(index),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            TextFormField(
              key: ValueKey('profile-id-$index-${profile['id']}'),
              initialValue: profile['id']?.toString() ?? '',
              decoration: _smallInputDecoration('Profile ID'),
              onFieldSubmitted: (value) =>
                  controller.updateCurrentBuildProfile(index, id: value),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: profile['target']?.toString() ?? 'web',
                    decoration: _smallInputDecoration('Target'),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(value: 'web', child: Text('Web')),
                      DropdownMenuItem(
                          value: 'android', child: Text('Android')),
                      DropdownMenuItem(
                          value: 'desktop', child: Text('Desktop')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        controller.updateCurrentBuildProfile(
                          index,
                          target: value,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: profile['mode']?.toString() ?? 'debug',
                    decoration: _smallInputDecoration('Mode'),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(value: 'debug', child: Text('Debug')),
                      DropdownMenuItem(
                          value: 'release', child: Text('Release')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        controller.updateCurrentBuildProfile(
                          index,
                          mode: value,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  Color _parseHexColor(String? value, {required Color fallback}) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) {
      return fallback;
    }
    final normalized = raw.startsWith('#') ? raw.substring(1) : raw;
    if (normalized.length != 6) {
      return fallback;
    }
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed == null) {
      return fallback;
    }
    return Color(0xFF000000 | parsed);
  }

  List<String> _effectiveAppPageSlugs(StudioController controller) {
    final visibleSlugs = controller.pages.map((page) => page.slug).toSet();
    final selected = _selectedAppPageSlugs
        .where(visibleSlugs.contains)
        .toList(growable: false);
    if (selected.isNotEmpty) {
      return selected;
    }
    return controller.pages.map((page) => page.slug).toList(growable: false);
  }

  Widget _buildPromptPanel(StudioController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF7C3AED)),
            const SizedBox(width: 6),
            const Text(
              'AI 页面生成',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _promptController,
          maxLines: 3,
          minLines: 2,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            hintText: '描述你想要的页面，如：一个销售团队仪表盘，展示营收、转化率和签约管线',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPageType,
                  isDense: true,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(
                        value: 'dashboard', child: Text('Dashboard')),
                    DropdownMenuItem(value: 'form', child: Text('Form')),
                    DropdownMenuItem(
                        value: 'table-list', child: Text('Table / List')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPageType = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 36,
                child: FilledButton.icon(
                  onPressed: controller.isGenerating
                      ? null
                      : () {
                          controller.generatePageFromPrompt(
                            prompt: _promptController.text,
                            pageType: _selectedPageType,
                          );
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                  ),
                  icon: controller.isGenerating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(controller.isGenerating ? '生成中…' : 'AI 生成页面'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'AI 二次修改',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _instructionController,
          maxLines: 2,
          minLines: 1,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            hintText: '基于当前页面继续修改，如：增加搜索筛选和操作按钮，并把标题改成客户运营看板',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF2563EB), width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 36,
          child: FilledButton.icon(
            onPressed: controller.isApplyingInstruction ||
                    controller.currentDocument == null
                ? null
                : () {
                    controller.updateCurrentPageByInstruction(
                      instruction: _instructionController.text,
                    );
                  },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
            ),
            icon: controller.isApplyingInstruction
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_fix_high_rounded, size: 16),
            label: Text(controller.isApplyingInstruction ? '修改中…' : '应用 AI 修改'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 36,
          child: OutlinedButton.icon(
            onPressed:
                controller.isExplaining || controller.currentDocument == null
                    ? null
                    : () {
                        controller.explainCurrentPage();
                      },
            icon: controller.isExplaining
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.tips_and_updates_outlined, size: 16),
            label: Text(controller.isExplaining ? '解释中…' : '解释当前页'),
          ),
        ),
        if (controller.lastExplanation != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(
                    text: _buildExplanationClipboardText(
                        controller.lastExplanation!),
                  ),
                );
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('页面解释已复制到剪贴板')),
                );
              },
              icon: const Icon(Icons.copy_all_rounded, size: 16),
              label: const Text('复制解释'),
            ),
          ),
        ],
      ],
    );
  }

  String _buildExplanationClipboardText(
      PageExplanationResultModel explanation) {
    final buffer = StringBuffer()
      ..writeln('页面解释')
      ..writeln('页面类型：${explanation.pageType}')
      ..writeln('摘要：${explanation.summary}');
    if (explanation.structure.isNotEmpty) {
      buffer.writeln('结构：');
      for (final line in explanation.structure) {
        buffer.writeln(line);
      }
    }
    if (explanation.actionSummary.isNotEmpty) {
      buffer.writeln('动作：');
      for (final item in explanation.actionSummary) {
        buffer.writeln('- $item');
      }
    }
    if (explanation.bindingSummary.isNotEmpty) {
      buffer.writeln('绑定：');
      for (final item in explanation.bindingSummary) {
        buffer.writeln('- $item');
      }
    }
    if (explanation.warnings.isNotEmpty) {
      buffer.writeln('警告：');
      for (final item in explanation.warnings) {
        buffer.writeln('- $item');
      }
    }
    return buffer.toString().trimRight();
  }

  List<Widget> _buildPageRuntimeLaunchSection(
    StudioController controller,
    PageDocumentModel? document,
  ) {
    final links = <_RuntimeLaunchLink>[
      if ((document?.stableUri ?? '').isNotEmpty)
        _RuntimeLaunchLink(
          label: '复制 Runtime 稳定链接',
          url: _buildRuntimeUrl(
            serverUrl: controller.repository.baseUrl,
            pageUri: document!.stableUri,
          ),
        ),
      if ((document?.versionUri ?? '').isNotEmpty)
        _RuntimeLaunchLink(
          label: '复制 Runtime 版本链接',
          url: _buildRuntimeUrl(
            serverUrl: controller.repository.baseUrl,
            pageUri: document!.versionUri,
          ),
        ),
    ].where((link) => link.url != null && link.url!.isNotEmpty).toList();

    if (links.isEmpty) {
      return const <Widget>[];
    }

    return <Widget>[
      const SizedBox(height: 10),
      _buildRuntimeLinkCard(
        title: 'Runtime 访问',
        accentColor: const Color(0xFF0F766E),
        borderColor: const Color(0xFF99F6E4),
        backgroundColor: const Color(0xFFF0FDFA),
        textColor: const Color(0xFF115E59),
        links: links,
      ),
    ];
  }

  List<Widget> _buildAppRuntimeLaunchSection(
    StudioController controller,
    AppDocumentModel app, {
    String? activeRoute,
  }) {
    final links = <_RuntimeLaunchLink>[
      if ((app.stableUri ?? '').isNotEmpty)
        _RuntimeLaunchLink(
          label: activeRoute == null || activeRoute.isEmpty
              ? '复制 Runtime 稳定链接'
              : '复制当前路由稳定链接',
          url: _buildRuntimeUrl(
            serverUrl: controller.repository.baseUrl,
            appUri: app.stableUri,
            route: activeRoute,
          ),
        ),
      if ((app.versionUri ?? '').isNotEmpty)
        _RuntimeLaunchLink(
          label: activeRoute == null || activeRoute.isEmpty
              ? '复制 Runtime 版本链接'
              : '复制当前路由版本链接',
          url: _buildRuntimeUrl(
            serverUrl: controller.repository.baseUrl,
            appUri: app.versionUri,
            route: activeRoute,
          ),
        ),
    ].where((link) => link.url != null && link.url!.isNotEmpty).toList();

    if (links.isEmpty) {
      return const <Widget>[];
    }

    return <Widget>[
      const SizedBox(height: 8),
      _buildRuntimeLinkCard(
        title: 'Runtime 访问',
        accentColor: const Color(0xFFEA580C),
        borderColor: const Color(0xFFFED7AA),
        backgroundColor: const Color(0xFFFFFBEB),
        textColor: const Color(0xFF9A3412),
        links: links,
      ),
    ];
  }

  Widget _buildRuntimeLinkCard({
    required String title,
    required Color accentColor,
    required Color borderColor,
    required Color backgroundColor,
    required Color textColor,
    required List<_RuntimeLaunchLink> links,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.open_in_new_rounded, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: links
                .map(
                  (link) => ActionChip(
                    avatar: Icon(
                      Icons.copy_all_rounded,
                      size: 16,
                      color: textColor,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: borderColor),
                    label: Text(
                      link.label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => _copyText(
                      link.url!,
                      '${link.label}已复制到剪贴板',
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  String? _buildRuntimeUrl({
    required String serverUrl,
    String? pageUri,
    String? appUri,
    String? route,
  }) {
    final runtimeBaseUrl = widget.runtimeBaseUrl?.trim();
    if (runtimeBaseUrl == null || runtimeBaseUrl.isEmpty) {
      return null;
    }

    try {
      final baseUri = Uri.parse(runtimeBaseUrl);
      final query = <String, String>{
        ...baseUri.queryParameters,
        'server': serverUrl,
      };
      query.removeWhere((key, value) => value.trim().isEmpty);

      if (pageUri != null && pageUri.isNotEmpty) {
        query
          ..remove('app')
          ..remove('appSlug')
          ..remove('appUri')
          ..remove('appVersion')
          ..remove('appRoute')
          ..remove('route')
          ..remove('pageSlug')
          ..remove('pageVersion')
          ..remove('pageUri')
          ..remove('slug')
          ..remove('uri')
          ..remove('version');
        query['uri'] = pageUri;
      }

      if (appUri != null && appUri.isNotEmpty) {
        query
          ..remove('app')
          ..remove('appSlug')
          ..remove('appUri')
          ..remove('appVersion')
          ..remove('appRoute')
          ..remove('route')
          ..remove('pageSlug')
          ..remove('pageVersion')
          ..remove('pageUri')
          ..remove('slug')
          ..remove('uri')
          ..remove('version');
        query['appUri'] = appUri;
        if (route != null && route.isNotEmpty) {
          query['route'] = route;
        }
      }

      return baseUri.replace(queryParameters: query).toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _copyText(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _panel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E5E4)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RuntimeLaunchLink {
  const _RuntimeLaunchLink({
    required this.label,
    required this.url,
  });

  final String label;
  final String? url;
}
