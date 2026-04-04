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
  PageDocumentModel? _currentPage;
  String? _activeResourceUri;
  String? _error;
  String _statusMessage = '正在连接 MCP UI Server...';
  bool _isLoadingCatalog = true;
  bool _isLoadingPage = false;
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
      _statusMessage = '正在加载已发布页面清单...';
    });

    try {
      final pages = await _repository.listPages();
      if (!mounted) {
        return;
      }

      setState(() {
        _pages = pages;
        _isLoadingCatalog = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _pages = <PageSummaryModel>[];
        _isLoadingCatalog = false;
        _error = '无法连接页面服务：$error';
        _statusMessage = '当前无法读取已发布页面';
      });
    }

    final preferredPageUri = _activeResourceUri ?? widget.config.pageUri;
    if (preferredPageUri != null) {
      await _loadPageByUri(preferredPageUri, silentStatus: true);
      return;
    }

    final initialSlug =
        widget.config.pageSlug ??
        _currentPage?.slug ??
        (_pages.isEmpty ? null : _pages.first.slug);
    if (initialSlug != null) {
      await _loadPage(
        initialSlug,
        version: initialSlug == widget.config.pageSlug
            ? widget.config.pageVersion
            : _currentPage?.version,
        silentStatus: true,
      );
      return;
    }

    if (mounted) {
      setState(() {
        _statusMessage = '当前还没有可渲染的已发布页面';
      });
    }
  }

  Future<void> _loadPage(
    String slug, {
    String? version,
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

  Future<void> _loadPageByUri(String uri, {bool silentStatus = false}) async {
    setState(() {
      _isLoadingPage = true;
      _error = null;
      if (!silentStatus) {
        _statusMessage = '正在解析资源 URI...';
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
            tooltip: '刷新页面清单',
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
                    SizedBox(width: 320, child: catalog),
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
    final selectedSlug = _currentPage?.slug;
    final Widget catalogBody;

    if (_isLoadingCatalog) {
      catalogBody = showSidebar
          ? const Expanded(child: Center(child: CircularProgressIndicator()))
          : const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            );
    } else if (_pages.isEmpty) {
      catalogBody = showSidebar
          ? Expanded(
              child: _EmptyCatalog(
                statusMessage: _statusMessage,
                error: _error,
                serverUrl: widget.config.serverUrl,
              ),
            )
          : SizedBox(
              height: 180,
              child: _EmptyCatalog(
                statusMessage: _statusMessage,
                error: _error,
                serverUrl: widget.config.serverUrl,
              ),
            );
    } else if (showSidebar) {
      catalogBody = Expanded(
        child: ListView.separated(
          itemCount: _pages.length,
          separatorBuilder: (BuildContext context, int index) =>
              const SizedBox(height: 10),
          itemBuilder: (BuildContext context, int index) {
            final page = _pages[index];
            final isSelected = page.slug == selectedSlug;
            return _PageSummaryTile(
              page: page,
              isSelected: isSelected,
              onTap: () => _loadPage(page.slug),
            );
          },
        ),
      );
    } else {
      catalogBody = DropdownButtonFormField<String>(
        initialValue: selectedSlug ?? _pages.first.slug,
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
              'Published Pages',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Runtime 只负责读取已发布页面并渲染，不包含 Studio 的编辑能力。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF57534E),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            catalogBody,
          ],
        ),
      ),
    );
  }

  Widget _buildRuntimePanel(BuildContext context) {
    if (_isLoadingPage && _currentPage == null) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentPage == null) {
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
                    Icons.view_quilt_outlined,
                    size: 54,
                    color: Color(0xFF0F766E),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Runtime 已就绪，但还没有选中的页面',
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

    final page = _currentPage!;

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
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: RuntimeCanvas(
                          definition: page.definition,
                          revision: _runtimeRevision,
                          onToolCall: _handleToolCall,
                        ),
                      ),
                      if (_isLoadingPage)
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
              '没有读取到已发布页面',
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
