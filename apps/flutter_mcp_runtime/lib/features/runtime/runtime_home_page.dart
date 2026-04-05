import 'package:flutter/material.dart';

import '../../core/config/runtime_launch_config.dart';
import '../../core/models/page_models.dart';
import '../../core/services/page_repository.dart';
import 'runtime_canvas.dart';

class RuntimeHomePage extends StatefulWidget {
  const RuntimeHomePage({super.key, required this.config});

  final RuntimeLaunchConfig config;

  @override
  State<RuntimeHomePage> createState() => _RuntimeHomePageState();
}

class _RuntimeHomePageState extends State<RuntimeHomePage> {
  late final PageRepository _repository;

  List<PageSummaryModel> _pages = <PageSummaryModel>[];
  List<AppSummaryModel> _apps = <AppSummaryModel>[];
  PageDocumentModel? _currentPage;
  AppDocumentModel? _currentApp;
  String? _activeResourceUri;
  String? _activeAppResourceUri;
  String? _activeAppRoute;
  String? _error;
  String _statusMessage = '正在连接 MCP UI Server...';
  bool _isLoadingCatalog = true;
  bool _isLoadingPage = false;
  bool _isLoadingApp = false;
  int _runtimeRevision = 0;

  @override
  void initState() {
    super.initState();
    _repository = PageRepository(baseUrl: widget.config.serverUrl);
    _bootstrap();
  }

  @override
  void dispose() {
    _repository.close();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoadingCatalog = true;
      _error = null;
      _statusMessage = '正在加载已发布页面与应用清单...';
    });

    List<PageSummaryModel> loadedPages = <PageSummaryModel>[];
    List<AppSummaryModel> loadedApps = <AppSummaryModel>[];
    final catalogErrors = <String>[];

    try {
      loadedPages = await _repository.listPages();
    } catch (error) {
      catalogErrors.add('页面清单加载失败：$error');
    }

    try {
      loadedApps = await _repository.listApps();
    } catch (error) {
      catalogErrors.add('应用清单加载失败：$error');
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _pages = loadedPages;
      _apps = loadedApps;
      _isLoadingCatalog = false;
      if (loadedPages.isEmpty &&
          loadedApps.isEmpty &&
          catalogErrors.isNotEmpty) {
        _error = catalogErrors.join('\n');
        _statusMessage = '当前无法读取已发布资源';
      } else if (loadedApps.isNotEmpty) {
        _statusMessage =
            '已读取 ${loadedApps.length} 个应用与 ${loadedPages.length} 个页面';
      } else if (loadedPages.isNotEmpty) {
        _statusMessage = '已读取 ${loadedPages.length} 个已发布页面';
      } else {
        _statusMessage = '当前还没有可渲染的已发布资源';
      }
    });

    final hasStickyAppTarget =
        _currentApp != null ||
        widget.config.appUri != null ||
        widget.config.appSlug != null;
    final hasStickyPageTarget =
        _currentPage != null ||
        widget.config.pageUri != null ||
        widget.config.pageSlug != null;

    if (hasStickyAppTarget || (!hasStickyPageTarget && loadedApps.isNotEmpty)) {
      final appUri = _activeAppResourceUri ?? widget.config.appUri;
      if (appUri != null) {
        await _loadAppByUri(
          appUri,
          desiredRoute: _activeAppRoute ?? widget.config.appRoute,
          silentStatus: true,
        );
        return;
      }

      final appSlug =
          _currentApp?.slug ??
          widget.config.appSlug ??
          (loadedApps.isEmpty ? null : loadedApps.first.slug);
      if (appSlug != null) {
        await _loadApp(
          appSlug,
          version: appSlug == widget.config.appSlug
              ? widget.config.appVersion
              : _currentApp?.version,
          desiredRoute: _activeAppRoute ?? widget.config.appRoute,
          silentStatus: true,
        );
        return;
      }
    }

    final pageUri = _activeResourceUri ?? widget.config.pageUri;
    if (pageUri != null) {
      await _loadPageByUri(pageUri, silentStatus: true);
      return;
    }

    final pageSlug =
        _currentPage?.slug ??
        widget.config.pageSlug ??
        (loadedPages.isEmpty ? null : loadedPages.first.slug);
    if (pageSlug != null) {
      await _loadPage(
        pageSlug,
        version: pageSlug == widget.config.pageSlug
            ? widget.config.pageVersion
            : _currentPage?.version,
        silentStatus: true,
      );
    }
  }

  Future<void> _loadPage(
    String slug, {
    String? version,
    bool preserveAppContext = false,
    bool silentStatus = false,
  }) async {
    setState(() {
      _isLoadingPage = true;
      _error = null;
      if (!silentStatus) {
        _statusMessage = '正在加载页面 $slug...';
      }
    });

    try {
      final document = await _repository.loadPage(slug, version: version);
      if (!mounted) {
        return;
      }

      setState(() {
        _currentPage = document;
        _activeResourceUri = null;
        if (!preserveAppContext) {
          _currentApp = null;
          _activeAppResourceUri = null;
          _activeAppRoute = null;
        }
        _runtimeRevision += 1;
        _isLoadingPage = false;
        _statusMessage = '已渲染页面 ${document.slug}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingPage = false;
        _error = '页面加载失败：$error';
        _statusMessage = '页面加载失败';
      });
    }
  }

  Future<void> _loadPageByUri(
    String uri, {
    bool preserveAppContext = false,
    bool silentStatus = false,
  }) async {
    setState(() {
      _isLoadingPage = true;
      _error = null;
      if (!silentStatus) {
        _statusMessage = '正在解析页面资源 URI...';
      }
    });

    try {
      final document = await _repository.resolvePageUri(uri);
      if (!mounted) {
        return;
      }

      setState(() {
        _currentPage = document;
        _activeResourceUri = uri;
        if (!preserveAppContext) {
          _currentApp = null;
          _activeAppResourceUri = null;
          _activeAppRoute = null;
        }
        _runtimeRevision += 1;
        _isLoadingPage = false;
        _statusMessage = '已通过资源 URI 渲染页面 ${document.slug}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingPage = false;
        _error = '资源解析失败：$error';
        _statusMessage = '资源解析失败';
      });
    }
  }

  Future<void> _loadApp(
    String slug, {
    String? version,
    String? desiredRoute,
    bool silentStatus = false,
  }) async {
    setState(() {
      _isLoadingApp = true;
      _error = null;
      if (!silentStatus) {
        _statusMessage = '正在加载应用 $slug...';
      }
    });

    try {
      final app = await _repository.loadApp(slug, version: version);
      await _activateApp(app, desiredRoute: desiredRoute, sourceUri: null);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingApp = false;
        _error = '应用加载失败：$error';
        _statusMessage = '应用加载失败';
      });
    }
  }

  Future<void> _loadAppByUri(
    String uri, {
    String? desiredRoute,
    bool silentStatus = false,
  }) async {
    setState(() {
      _isLoadingApp = true;
      _error = null;
      if (!silentStatus) {
        _statusMessage = '正在解析应用资源 URI...';
      }
    });

    try {
      final app = await _repository.resolveAppUri(uri);
      await _activateApp(app, desiredRoute: desiredRoute, sourceUri: uri);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingApp = false;
        _error = '应用资源解析失败：$error';
        _statusMessage = '应用资源解析失败';
      });
    }
  }

  Future<void> _activateApp(
    AppDocumentModel app, {
    String? desiredRoute,
    required String? sourceUri,
  }) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _currentApp = app;
      _currentPage = null;
      _activeResourceUri = null;
      _activeAppResourceUri = sourceUri;
      _activeAppRoute = null;
    });

    final targetRoute = _pickTargetRoute(
      app.schema,
      desiredRoute: desiredRoute,
    );
    if (targetRoute != null) {
      final routePath = targetRoute['path']?.toString();
      final pageUri = targetRoute['pageUri']?.toString();
      final pageSlug = targetRoute['pageSlug']?.toString();
      if (routePath != null && routePath.isNotEmpty) {
        setState(() {
          _activeAppRoute = routePath;
        });
      }

      if (pageUri != null && pageUri.isNotEmpty) {
        await _loadPageByUri(
          pageUri,
          preserveAppContext: true,
          silentStatus: true,
        );
      } else if (pageSlug != null && pageSlug.isNotEmpty) {
        await _loadPage(pageSlug, preserveAppContext: true, silentStatus: true);
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingApp = false;
      if (_error == null) {
        _statusMessage = _activeAppRoute == null
            ? '已加载应用 ${app.name}'
            : '已加载应用 ${app.name} · ${_activeAppRoute!}';
      }
    });
  }

  Future<void> _openAppRoute(String routePath) async {
    final app = _currentApp;
    if (app == null) {
      return;
    }

    final routes = _extractRoutesFromSchema(app.schema);
    Map<String, dynamic>? route;
    for (final item in routes) {
      if (item['path']?.toString() == routePath) {
        route = item;
        break;
      }
    }

    if (route == null) {
      setState(() {
        _error = '未找到应用路由：$routePath';
      });
      return;
    }

    setState(() {
      _activeAppRoute = routePath;
    });

    final pageUri = route['pageUri']?.toString();
    final pageSlug = route['pageSlug']?.toString();
    if (pageUri != null && pageUri.isNotEmpty) {
      await _loadPageByUri(
        pageUri,
        preserveAppContext: true,
        silentStatus: true,
      );
    } else if (pageSlug != null && pageSlug.isNotEmpty) {
      await _loadPage(pageSlug, preserveAppContext: true, silentStatus: true);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      if (_error == null) {
        _statusMessage = '已切换应用路由：$routePath';
      }
    });
  }

  Future<Map<String, dynamic>> _handleToolCall(
    String toolName,
    Map<String, dynamic> params,
  ) async {
    final result = await _repository.invokeTool(toolName, params);
    if (!mounted) {
      return result;
    }

    setState(() {
      _statusMessage = '已执行工具：$toolName';
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Flutter MCP Runtime'),
            Text(
              widget.config.serverUrl,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: '刷新资源清单',
            onPressed: _bootstrap,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final showSidebar = constraints.maxWidth >= 1080;
            final catalog = _buildCatalogPanel(
              context,
              showSidebar: showSidebar,
            );
            final runtime = _buildRuntimePanel(context);

            if (showSidebar) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(width: 340, child: catalog),
                    const SizedBox(width: 20),
                    Expanded(child: runtime),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: <Widget>[
                  catalog,
                  const SizedBox(height: 16),
                  Expanded(child: runtime),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCatalogPanel(BuildContext context, {required bool showSidebar}) {
    final theme = Theme.of(context);
    final selectedPageSlug = _currentPage?.slug;
    final selectedAppSlug = _currentApp?.slug;

    Widget content;
    if (_isLoadingCatalog) {
      content = SizedBox(
        height: showSidebar ? null : 120,
        child: const Center(child: CircularProgressIndicator()),
      );
    } else if (_apps.isEmpty && _pages.isEmpty) {
      content = SizedBox(
        height: showSidebar ? null : 180,
        child: _EmptyCatalog(
          statusMessage: _statusMessage,
          error: _error,
          serverUrl: widget.config.serverUrl,
        ),
      );
    } else if (showSidebar) {
      content = Expanded(
        child: ListView(
          children: <Widget>[
            if (_apps.isNotEmpty) ...<Widget>[
              _CatalogSectionLabel(
                title: 'Published Apps',
                subtitle: '阶段 2 的多页应用骨架与导航入口。',
              ),
              const SizedBox(height: 10),
              ..._apps.map(
                (app) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AppSummaryTile(
                    app: app,
                    isSelected: selectedAppSlug == app.slug,
                    onTap: () => _loadApp(app.slug),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (_pages.isNotEmpty) ...<Widget>[
              _CatalogSectionLabel(
                title: 'Standalone Pages',
                subtitle: '单页模式仍然保留，便于直接预览页面资源。',
              ),
              const SizedBox(height: 10),
              ..._pages.map(
                (page) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PageSummaryTile(
                    page: page,
                    isSelected:
                        selectedPageSlug == page.slug && _currentApp == null,
                    onTap: () => _loadPage(page.slug),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_apps.isNotEmpty) ...<Widget>[
            const _CatalogSectionLabel(
              title: '应用入口',
              subtitle: '选择一个应用骨架继续浏览页面路由。',
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedAppSlug,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '选择应用',
              ),
              items: _apps
                  .map(
                    (app) => DropdownMenuItem<String>(
                      value: app.slug,
                      child: Text(app.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _loadApp(value);
                }
              },
            ),
            const SizedBox(height: 14),
          ],
          if (_pages.isNotEmpty) ...<Widget>[
            const _CatalogSectionLabel(title: '单页入口', subtitle: '也可以直接查看单页资源。'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _currentApp == null ? selectedPageSlug : null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '选择页面',
              ),
              items: _pages
                  .map(
                    (page) => DropdownMenuItem<String>(
                      value: page.slug,
                      child: Text(page.title),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _loadPage(value);
                }
              },
            ),
          ],
        ],
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E5E4)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Runtime Catalog',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Runtime 现在同时支持单页资源与多页应用骨架，可按 App Schema 渲染导航壳。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF57534E),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildRuntimePanel(BuildContext context) {
    if ((_isLoadingPage || _isLoadingApp) &&
        _currentPage == null &&
        _currentApp == null) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentPage == null && _currentApp == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE7E5E4)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.space_dashboard_outlined,
                    size: 54,
                    color: Color(0xFF0F766E),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Runtime 已就绪，但还没有选中的页面或应用',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _error ?? _statusMessage,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF57534E),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_currentApp != null) {
      return _buildAppRuntimePanel(context, _currentApp!);
    }

    return _buildPageRuntimePanel(context, _currentPage!);
  }

  Widget _buildPageRuntimePanel(BuildContext context, PageDocumentModel page) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E5E4)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 32,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  page.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                _MetaChip(label: 'slug', value: page.slug),
                if (page.version != null)
                  _MetaChip(label: 'version', value: page.version!),
                if (page.isStable)
                  const _MetaChip(label: 'channel', value: 'stable'),
              ],
            ),
            if ((page.description ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                page.description!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF57534E),
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 14),
            SelectableText(
              _activeResourceUri ?? page.stableUri ?? page.versionUri ?? '-',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF0F766E)),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _buildViewportContainer(
                child: RuntimeCanvas(
                  definition: page.definition,
                  revision: _runtimeRevision,
                  onToolCall: _handleToolCall,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _error ?? _statusMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _error == null
                    ? const Color(0xFF57534E)
                    : const Color(0xFFB91C1C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppRuntimePanel(BuildContext context, AppDocumentModel app) {
    final routes = _extractRoutesFromSchema(app.schema);
    final layoutShell = _asMap(app.schema['layoutShell']);
    final theme = _asMap(app.schema['theme']);
    final navigationStyle =
        layoutShell['navigationStyle']?.toString() ?? 'sidebar';
    final isDark = theme['mode']?.toString() == 'dark';
    final primaryColor = _parseHexColor(
      theme['primaryColor']?.toString(),
      fallback: const Color(0xFF0F766E),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E5E4)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 32,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  app.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                _MetaChip(label: 'app', value: app.slug),
                if (app.version != null)
                  _MetaChip(label: 'version', value: app.version!),
                _MetaChip(label: 'shell', value: navigationStyle),
              ],
            ),
            if ((app.description ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                app.description!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF57534E),
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 10),
            if ((app.versionUri ?? app.stableUri ?? '').isNotEmpty)
              SelectableText(
                _activeAppResourceUri ?? app.versionUri ?? app.stableUri ?? '-',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF0F766E)),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final useSidebarShell =
                      navigationStyle == 'sidebar' &&
                      constraints.maxWidth >= 960;
                  final shellBackground = isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFFFFCF7);
                  final shellBorder = isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF3E8D8);

                  final shell = Container(
                    decoration: BoxDecoration(
                      color: shellBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: shellBorder),
                    ),
                    child: useSidebarShell
                        ? Row(
                            children: <Widget>[
                              SizedBox(
                                width: 228,
                                child: _buildAppNavigationRail(
                                  app,
                                  routes,
                                  primaryColor: primaryColor,
                                  isDark: isDark,
                                ),
                              ),
                              Expanded(
                                child: _buildAppPageViewport(
                                  context,
                                  primaryColor: primaryColor,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: <Widget>[
                              _buildAppNavigationHeader(
                                app,
                                routes,
                                compact: navigationStyle == 'tabs',
                                primaryColor: primaryColor,
                                isDark: isDark,
                              ),
                              Expanded(
                                child: _buildAppPageViewport(
                                  context,
                                  primaryColor: primaryColor,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                  );

                  return shell;
                },
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _error ?? _statusMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _error == null
                    ? const Color(0xFF57534E)
                    : const Color(0xFFB91C1C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppNavigationRail(
    AppDocumentModel app,
    List<Map<String, dynamic>> routes, {
    required Color primaryColor,
    required bool isDark,
  }) {
    final railBackground = isDark
        ? const Color(0xFF111827)
        : const Color(0xFFF6EDE1);
    final railText = isDark ? const Color(0xFFE5E7EB) : const Color(0xFF7C2D12);
    final railMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF9A3412);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: railBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            app.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: railText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            app.description ?? 'Sidebar shell',
            style: TextStyle(color: railMuted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (routes.isEmpty)
            Text(
              '当前应用还没有路由配置',
              style: TextStyle(color: railMuted, fontSize: 12),
            )
          else
            ...routes.map((route) {
              final path = route['path']?.toString() ?? '';
              final selected = path == _activeAppRoute;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openAppRoute(path),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
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
                            _routeLabel(route),
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
    AppDocumentModel app,
    List<Map<String, dynamic>> routes, {
    required bool compact,
    required Color primaryColor,
    required bool isDark,
  }) {
    final headerBackground = isDark
        ? const Color(0xFF111827)
        : const Color(0xFFF6EDE1);
    final headerText = isDark
        ? const Color(0xFFE5E7EB)
        : const Color(0xFF7C2D12);
    final headerMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF9A3412);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: headerBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            app.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: headerText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            app.description ?? (compact ? 'Tabs shell' : 'Topbar shell'),
            style: TextStyle(color: headerMuted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          if (routes.isEmpty)
            Text(
              '当前应用还没有路由配置',
              style: TextStyle(color: headerMuted, fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: routes.map((route) {
                final path = route['path']?.toString() ?? '';
                final selected = path == _activeAppRoute;
                return ChoiceChip(
                  selected: selected,
                  selectedColor: primaryColor,
                  backgroundColor: isDark
                      ? const Color(0xFF1F2937)
                      : const Color(0xFFFFF7ED),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : headerText,
                    fontWeight: FontWeight.w600,
                  ),
                  label: Text(_routeLabel(route)),
                  onSelected: (_) => _openAppRoute(path),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAppPageViewport(
    BuildContext context, {
    required Color primaryColor,
    required bool isDark,
  }) {
    final document = _currentPage;
    final titleColor = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF0F172A);
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            document?.title ?? '未绑定页面',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _activeAppRoute == null ? '应用预览' : '当前路由：$_activeAppRoute',
            style: TextStyle(color: mutedColor, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0B1220) : Colors.white,
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.24),
                  ),
                ),
                child: document == null
                    ? Center(
                        child: Text(
                          '当前路由还没有绑定可渲染页面',
                          style: TextStyle(color: mutedColor),
                        ),
                      )
                    : RuntimeCanvas(
                        definition: document.definition,
                        revision: _runtimeRevision,
                        onToolCall: _handleToolCall,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewportContainer({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: child),
            if (_isLoadingPage || _isLoadingApp)
              const Positioned(
                top: 16,
                right: 16,
                child: Chip(
                  avatar: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  label: Text('Refreshing'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic>? _pickTargetRoute(
    Map<String, dynamic> schema, {
    String? desiredRoute,
  }) {
    final routes = _extractRoutesFromSchema(schema);
    if (routes.isEmpty) {
      return null;
    }

    if (desiredRoute != null && desiredRoute.isNotEmpty) {
      for (final route in routes) {
        if (route['path']?.toString() == desiredRoute) {
          return route;
        }
      }
    }

    final homePage = schema['homePage']?.toString();
    if (homePage != null && homePage.isNotEmpty) {
      for (final route in routes) {
        if (route['pageSlug']?.toString() == homePage) {
          return route;
        }
      }
    }

    return routes.first;
  }

  List<Map<String, dynamic>> _extractRoutesFromSchema(
    Map<String, dynamic> schema,
  ) {
    final routes = schema['routes'];
    if (routes is! List) {
      return const <Map<String, dynamic>>[];
    }
    return routes
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
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

  Color _parseHexColor(String? rawValue, {required Color fallback}) {
    if (rawValue == null) {
      return fallback;
    }
    final normalized = rawValue.trim().replaceFirst('#', '');
    if (normalized.length != 6) {
      return fallback;
    }
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) {
      return fallback;
    }
    return Color(0xFF000000 | value);
  }

  String _routeLabel(Map<String, dynamic> route) {
    return route['title']?.toString() ??
        route['pageSlug']?.toString() ??
        route['path']?.toString() ??
        '-';
  }
}

class _CatalogSectionLabel extends StatelessWidget {
  const _CatalogSectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF57534E),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _AppSummaryTile extends StatelessWidget {
  const _AppSummaryTile({
    required this.app,
    required this.isSelected,
    required this.onTap,
  });

  final AppSummaryModel app;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDFA) : const Color(0xFFFFFBF5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF14B8A6)
                : const Color(0xFFF3E8D8),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.account_tree_outlined,
                    size: 16,
                    color: Color(0xFF0F766E),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      app.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if ((app.description ?? '').isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  app.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF57534E),
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                app.stableUri,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF0F766E)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageSummaryTile extends StatelessWidget {
  const _PageSummaryTile({
    required this.page,
    required this.isSelected,
    required this.onTap,
  });

  final PageSummaryModel page;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDFA) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF14B8A6)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                page.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if ((page.description ?? '').isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  page.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF57534E),
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                page.stableUri,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF0F766E)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7E5E4)),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF1C1917)),
          children: <InlineSpan>[
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog({
    required this.statusMessage,
    required this.error,
    required this.serverUrl,
  });

  final String statusMessage;
  final String? error;
  final String serverUrl;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Color(0xFF64748B),
            ),
            const SizedBox(height: 14),
            Text(
              '没有读取到已发布资源',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error ?? statusMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF57534E),
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SelectableText(
              serverUrl,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF0F766E)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
