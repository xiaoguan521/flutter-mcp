import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/page_models.dart';
import '../../core/services/mcp_bridge_service.dart';
import '../../core/services/page_repository.dart';
import '../persistence/local_draft_store.dart';

class StudioController extends ChangeNotifier {
  StudioController({
    required this.repository,
    required this.draftStore,
    required this.mcpBridgeService,
  });

  final PageRepository repository;
  final LocalDraftStore draftStore;
  final McpBridgeService mcpBridgeService;
  final Uuid _uuid = const Uuid();

  bool isBusy = false;
  bool isSaving = false;
  bool isLoadingApps = false;
  bool isCreatingApp = false;
  bool isGenerating = false;
  bool isExplaining = false;
  bool isApplyingInstruction = false;
  bool isValidating = false;
  bool isUsingBundledFallback = false;
  bool isMcpConnected = false;
  String? error;
  String statusMessage = '等待加载页面';
  String? selectedSlug;
  String? selectedVersion;
  String? selectedAppSlug;
  String? selectedAppVersion;
  String? activeAppRoute;
  String? draftUpdatedAt;
  int sourceRevision = 0;
  int appSourceRevision = 0;

  List<PageSummaryModel> pages = <PageSummaryModel>[];
  List<PageVersionModel> versions = <PageVersionModel>[];
  List<AppSummaryModel> apps = <AppSummaryModel>[];
  List<AppVersionModel> appVersions = <AppVersionModel>[];
  List<PageTemplateModel> templates = <PageTemplateModel>[];
  List<ComponentCatalogItemModel> componentCatalog =
      <ComponentCatalogItemModel>[];
  PageDocumentModel? currentDocument;
  AppDocumentModel? currentAppDocument;
  GeneratedPageResultModel? lastGeneration;
  PageExplanationResultModel? lastExplanation;
  PageUpdateResultModel? lastInstructionUpdate;
  PageValidationResultModel? validationResult;
  AppValidationResultModel? appValidationResult;
  List<String> lastAppWarnings = <String>[];

  String get prettySource => const JsonEncoder.withIndent('  ')
      .convert(currentDocument?.definition ?? <String, dynamic>{});

  String get prettyAppSource => const JsonEncoder.withIndent('  ')
      .convert(currentAppDocument?.schema ?? <String, dynamic>{});

  int get runtimeRevision => sourceRevision;

  bool get canUseAiTools => !isUsingBundledFallback;

  List<Map<String, dynamic>> get currentAppRoutes => _extractRoutesFromSchema(
      currentAppDocument?.schema ?? <String, dynamic>{});

  List<Map<String, dynamic>> get contentBlocks {
    final definition = currentDocument?.definition;
    if (definition == null) {
      return const <Map<String, dynamic>>[];
    }
    final content = definition['content'];
    if (content is! Map<String, dynamic>) {
      return const <Map<String, dynamic>>[];
    }
    final children = content['children'];
    if (children is! List) {
      return const <Map<String, dynamic>>[];
    }
    return children
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> bootstrap() async {
    await refreshPages(selectFirst: true);
    await refreshApps();
    await _loadAiMetadata();
    if (currentDocument != null && canUseAiTools) {
      await validateCurrentPage(showStatus: false, replaceWithNormalized: true);
    }
    isMcpConnected = await mcpBridgeService.ensureConnected(
      baseUrl: repository.baseUrl,
    );
    notifyListeners();
  }

  Future<void> reconnectMcp() async {
    isMcpConnected = await mcpBridgeService.ensureConnected(
      baseUrl: repository.baseUrl,
    );
    statusMessage = isMcpConnected
        ? 'MCP Streamable HTTP 已连接'
        : 'MCP 连接失败，仍可通过 HTTP API 工作';
    notifyListeners();
  }

  Future<void> refreshWorkspace() async {
    await refreshPages(selectFirst: currentDocument == null);
    await refreshApps(selectFirst: currentAppDocument == null);
  }

  Future<void> refreshPages({bool selectFirst = false}) async {
    isBusy = true;
    error = null;
    notifyListeners();

    try {
      pages = await repository.listPages();
      isUsingBundledFallback = false;
      statusMessage = '已从 MCP UI Server 拉取页面清单';
    } catch (_) {
      pages = await repository.loadBundledPageSummaries();
      isUsingBundledFallback = true;
      templates = _defaultTemplates();
      componentCatalog = <ComponentCatalogItemModel>[];
      statusMessage = '服务端不可用，已切换到内置样例';
    } finally {
      isBusy = false;
      notifyListeners();
    }

    if (selectFirst && pages.isNotEmpty) {
      await loadPage(pages.first.slug);
    }
  }

  Future<void> refreshApps({bool selectFirst = false}) async {
    if (isUsingBundledFallback) {
      apps = <AppSummaryModel>[];
      appVersions = <AppVersionModel>[];
      currentAppDocument = null;
      selectedAppSlug = null;
      selectedAppVersion = null;
      activeAppRoute = null;
      appValidationResult = null;
      lastAppWarnings = <String>[];
      notifyListeners();
      return;
    }

    isLoadingApps = true;
    notifyListeners();

    try {
      apps = await repository.listApps();
      if (selectedAppSlug != null &&
          apps.any((app) => app.slug == selectedAppSlug)) {
        appVersions = await repository.listAppVersions(selectedAppSlug!);
      } else {
        appVersions = <AppVersionModel>[];
      }
    } catch (loadError) {
      apps = <AppSummaryModel>[];
      appVersions = <AppVersionModel>[];
      currentAppDocument = null;
      selectedAppSlug = null;
      selectedAppVersion = null;
      activeAppRoute = null;
      appValidationResult = null;
      error ??= loadError.toString();
    } finally {
      isLoadingApps = false;
      notifyListeners();
    }

    if (selectFirst && apps.isNotEmpty) {
      await loadApp(apps.first.slug);
    }
  }

  Future<void> loadPage(
    String slug, {
    String? version,
    bool preserveAppContext = false,
  }) async {
    isBusy = true;
    error = null;
    notifyListeners();

    try {
      PageDocumentModel? document;
      if (isUsingBundledFallback) {
        document = await repository.loadBundledPage(slug);
      } else {
        document = await repository.loadPage(slug, version: version);
      }

      if (document == null) {
        throw Exception('页面不存在：$slug');
      }

      if (version == null && draftStore.hasDraft(slug)) {
        final draft = draftStore.readDraft(slug);
        if (draft != null) {
          document = document.copyWith(definition: _cloneMap(draft));
          draftUpdatedAt = draftStore.readDraftUpdatedAt(slug);
          statusMessage = '已恢复本地草稿';
        }
      } else {
        draftUpdatedAt = draftStore.readDraftUpdatedAt(slug);
      }

      selectedSlug = slug;
      selectedVersion = version ?? document.version;
      currentDocument =
          document.copyWith(definition: _cloneMap(document.definition));
      if (!preserveAppContext) {
        currentAppDocument = null;
        selectedAppSlug = null;
        selectedAppVersion = null;
        activeAppRoute = null;
        appValidationResult = null;
        appVersions = <AppVersionModel>[];
        lastAppWarnings = <String>[];
      }
      lastGeneration = null;
      lastExplanation = null;
      lastInstructionUpdate = null;

      if (isUsingBundledFallback) {
        versions = <PageVersionModel>[
          PageVersionModel(
            slug: document.slug,
            title: document.title,
            version: document.version ?? 'bundled',
            createdAt: document.updatedAt ?? '',
            isStable: true,
            author: 'bundled',
            stableUri: document.stableUri ?? '',
            versionUri: document.versionUri ?? '',
            note: '内置样例',
          ),
        ];
      } else {
        versions = await repository.listVersions(slug);
      }

      _bumpSource();
      if (canUseAiTools) {
        await validateCurrentPage(
            showStatus: false, replaceWithNormalized: true);
      } else {
        validationResult = null;
      }
    } catch (loadError) {
      error = loadError.toString();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> applySource(String source) async {
    try {
      final parsed = jsonDecode(source) as Map<String, dynamic>;
      currentDocument =
          currentDocument?.copyWith(definition: _cloneMap(parsed));
      lastExplanation = null;
      statusMessage = 'JSON 已应用到预览';
      error = null;
      await _persistDraft();
      _bumpSource();
      await validateCurrentPage(showStatus: true, replaceWithNormalized: true);
      notifyListeners();
    } catch (parseError) {
      error = 'JSON 解析失败：$parseError';
      statusMessage = 'JSON 解析失败';
      notifyListeners();
    }
  }

  Future<void> addBlock(String kind) async {
    final block = _buildSnippet(kind);
    _editableChildren().add(block);
    lastExplanation = null;
    statusMessage = '已添加 $kind 组件块';
    await _persistDraft();
    _bumpSource();
    await validateCurrentPage(showStatus: false, replaceWithNormalized: false);
    notifyListeners();
  }

  Future<void> removeBlock(int index) async {
    final children = _editableChildren();
    if (index < 0 || index >= children.length) {
      return;
    }
    children.removeAt(index);
    lastExplanation = null;
    statusMessage = '已删除组件块';
    await _persistDraft();
    _bumpSource();
    await validateCurrentPage(showStatus: false, replaceWithNormalized: false);
    notifyListeners();
  }

  Future<void> moveBlock(int oldIndex, int newIndex) async {
    final children = _editableChildren();
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = children.removeAt(oldIndex);
    children.insert(newIndex, item);
    lastExplanation = null;
    statusMessage = '已重新排序组件块';
    await _persistDraft();
    _bumpSource();
    await validateCurrentPage(showStatus: false, replaceWithNormalized: false);
    notifyListeners();
  }

  Future<void> restoreDraft() async {
    final slug = selectedSlug;
    if (slug == null) {
      return;
    }
    final draft = draftStore.readDraft(slug);
    if (draft == null) {
      return;
    }
    currentDocument = currentDocument?.copyWith(definition: _cloneMap(draft));
    lastExplanation = null;
    draftUpdatedAt = draftStore.readDraftUpdatedAt(slug);
    statusMessage = '已恢复草稿';
    _bumpSource();
    await validateCurrentPage(showStatus: false, replaceWithNormalized: false);
    notifyListeners();
  }

  Future<void> generatePageFromPrompt({
    required String prompt,
    required String pageType,
    String? seedTemplate,
    String? locale,
  }) async {
    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty) {
      error = '请输入页面需求描述';
      statusMessage = 'AI 生成失败';
      notifyListeners();
      return;
    }

    if (!canUseAiTools) {
      error = '当前服务端不可用，暂时无法生成页面草稿';
      statusMessage = 'AI 生成不可用';
      notifyListeners();
      return;
    }

    isGenerating = true;
    error = null;
    notifyListeners();

    try {
      final generated = await repository.generatePageFromPrompt(
        prompt: trimmedPrompt,
        pageType: pageType,
        seedTemplate: seedTemplate,
        locale: locale,
      );

      lastGeneration = generated;
      lastExplanation = null;
      lastInstructionUpdate = null;
      currentDocument = PageDocumentModel(
        slug: generated.slug,
        title: generated.title,
        description: generated.summary,
        definition: _cloneMap(generated.definition),
      );
      selectedSlug = generated.slug;
      selectedVersion = null;
      versions = <PageVersionModel>[];
      draftUpdatedAt = null;
      await _persistDraft();
      _bumpSource();
      statusMessage = 'AI 页面草稿已生成';
      await validateCurrentPage(showStatus: true, replaceWithNormalized: true);
    } catch (generationError) {
      error = generationError.toString();
      statusMessage = 'AI 生成失败';
    } finally {
      isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> updateCurrentPageByInstruction({
    required String instruction,
    String? locale,
  }) async {
    final trimmedInstruction = instruction.trim();
    if (trimmedInstruction.isEmpty) {
      error = '请输入修改指令';
      statusMessage = 'AI 修改失败';
      notifyListeners();
      return;
    }

    final document = currentDocument;
    if (document == null) {
      error = '当前没有可修改的页面';
      statusMessage = 'AI 修改失败';
      notifyListeners();
      return;
    }

    if (!canUseAiTools) {
      error = '当前服务端不可用，暂时无法应用 AI 修改';
      statusMessage = 'AI 修改不可用';
      notifyListeners();
      return;
    }

    isApplyingInstruction = true;
    error = null;
    notifyListeners();

    try {
      final updated = await repository.updatePageByInstruction(
        definition: document.definition,
        instruction: trimmedInstruction,
        locale: locale,
      );

      lastInstructionUpdate = updated;
      lastExplanation = null;
      currentDocument = document.copyWith(
        title: updated.title,
        description: updated.summary,
        definition: _cloneMap(updated.definition),
      );
      statusMessage = 'AI 修改已应用：${updated.appliedChanges.length} 项';
      await _persistDraft();
      _bumpSource();
      await validateCurrentPage(showStatus: true, replaceWithNormalized: true);
    } catch (updateError) {
      error = updateError.toString();
      statusMessage = 'AI 修改失败';
    } finally {
      isApplyingInstruction = false;
      notifyListeners();
    }
  }

  Future<void> loadApp(
    String slug, {
    String? version,
  }) async {
    if (isUsingBundledFallback) {
      error = '当前服务端不可用，暂时无法加载应用骨架';
      statusMessage = '应用加载不可用';
      notifyListeners();
      return;
    }

    isLoadingApps = true;
    error = null;
    notifyListeners();

    try {
      final document = await repository.loadApp(slug, version: version);
      currentAppDocument = _syncAppDocumentFromSchema(
        document.copyWith(schema: _cloneMap(document.schema)),
      );
      selectedAppSlug = slug;
      selectedAppVersion = version ?? document.version;
      _bumpAppSource();
      lastAppWarnings = <String>[];
      appVersions = await repository.listAppVersions(slug);
      await _loadInitialAppRoute(document);
      await validateCurrentApp(showStatus: false, replaceWithNormalized: true);
      statusMessage = '已加载应用骨架：${document.name}';
    } catch (loadError) {
      error = loadError.toString();
      statusMessage = '应用加载失败';
    } finally {
      isLoadingApps = false;
      notifyListeners();
    }
  }

  Future<void> createApp({
    required String name,
    String? description,
    List<String>? pageSlugs,
    String? navigationStyle,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      error = '请输入应用名称';
      statusMessage = '应用创建失败';
      notifyListeners();
      return;
    }

    if (isUsingBundledFallback) {
      error = '当前服务端不可用，暂时无法创建应用骨架';
      statusMessage = '应用创建不可用';
      notifyListeners();
      return;
    }

    isCreatingApp = true;
    error = null;
    notifyListeners();

    try {
      final result = await repository.createApp(
        name: trimmedName,
        description: description?.trim(),
        pageSlugs: pageSlugs,
        navigationStyle: navigationStyle,
        author: 'studio-user',
      );
      lastAppWarnings = result.warnings;
      currentAppDocument = _syncAppDocumentFromSchema(
        result.app.copyWith(schema: _cloneMap(result.app.schema)),
      );
      selectedAppSlug = result.app.slug;
      selectedAppVersion = result.app.version;
      _bumpAppSource();
      statusMessage = '应用骨架已创建：${result.app.versionUri ?? result.versionUri}';
      await refreshApps();
      await loadApp(result.app.slug, version: result.app.version);
    } catch (createError) {
      error = createError.toString();
      statusMessage = '应用创建失败';
    } finally {
      isCreatingApp = false;
      notifyListeners();
    }
  }

  Future<void> openAppRoute(String routePath) async {
    final route = currentAppRoutes.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item?['path']?.toString() == routePath,
          orElse: () => null,
        );
    if (route == null) {
      error = '未找到应用路由：$routePath';
      statusMessage = '应用路由切换失败';
      notifyListeners();
      return;
    }

    final pageSlug = route['pageSlug']?.toString();
    if (pageSlug == null || pageSlug.isEmpty) {
      error = '应用路由未绑定页面：$routePath';
      statusMessage = '应用路由切换失败';
      notifyListeners();
      return;
    }

    activeAppRoute = routePath;
    await loadPage(pageSlug, preserveAppContext: true);
    statusMessage = '已切换应用路由：$routePath';
    notifyListeners();
  }

  Future<void> applyAppSource(String source) async {
    try {
      final parsed = jsonDecode(source) as Map<String, dynamic>;
      final document = currentAppDocument;
      if (document == null) {
        return;
      }
      currentAppDocument = _syncAppDocumentFromSchema(
        document.copyWith(schema: _cloneMap(parsed)),
      );
      error = null;
      _bumpAppSource();
      await validateCurrentApp(showStatus: true, replaceWithNormalized: true);
      notifyListeners();
    } catch (parseError) {
      error = '应用 Schema 解析失败：$parseError';
      statusMessage = '应用 Schema 解析失败';
      notifyListeners();
    }
  }

  Future<void> validateCurrentApp({
    bool showStatus = true,
    bool replaceWithNormalized = false,
  }) async {
    final document = currentAppDocument;
    if (document == null || !canUseAiTools) {
      appValidationResult = null;
      return;
    }

    try {
      final result = await repository.validateApp(document.schema);
      appValidationResult = result;

      if (replaceWithNormalized && result.valid) {
        currentAppDocument = _syncAppDocumentFromSchema(
          document.copyWith(
            schema: _cloneMap(result.normalizedSchema),
          ),
        );
        _bumpAppSource();
      }

      if (showStatus) {
        if (result.valid && result.warnings.isEmpty) {
          statusMessage = '应用 Schema 校验通过';
        } else if (result.valid) {
          statusMessage = '应用 Schema 可用，但有 ${result.warnings.length} 条提示';
        } else {
          statusMessage = '应用 Schema 校验失败：${result.errors.length} 个错误';
        }
      }
    } catch (validationError) {
      appValidationResult = null;
      error = validationError.toString();
      if (showStatus) {
        statusMessage = '应用 Schema 校验失败';
      }
    } finally {
      notifyListeners();
    }
  }

  Future<SaveAppResultModel> persistCurrentApp({
    String? note,
  }) async {
    final document = currentAppDocument;
    if (document == null) {
      throw Exception('当前没有可固化的应用');
    }

    isSaving = true;
    error = null;
    notifyListeners();

    try {
      final saveResult = await repository.saveApp(
        slug: _schemaString(document.schema, 'slug') ?? document.slug,
        name: _schemaString(document.schema, 'name') ?? document.name,
        description: _schemaString(document.schema, 'description') ??
            document.description,
        note: note ?? 'Saved from studio',
        author: 'studio-user',
        schema: _cloneMap(document.schema),
      );

      currentAppDocument = _syncAppDocumentFromSchema(
        saveResult.app.copyWith(
          schema: _cloneMap(saveResult.app.schema),
        ),
      );
      selectedAppSlug = saveResult.app.slug;
      selectedAppVersion = saveResult.app.version;
      _bumpAppSource();
      statusMessage = '应用固化完成：${saveResult.versionUri}';
      await refreshApps();
      await loadApp(saveResult.app.slug, version: saveResult.app.version);
      return saveResult;
    } catch (saveError) {
      error = saveError.toString();
      statusMessage = '应用固化失败';
      rethrow;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> explainCurrentPage() async {
    final document = currentDocument;
    if (document == null) {
      error = '当前没有可解释的页面';
      statusMessage = '页面解释失败';
      notifyListeners();
      return;
    }

    if (!canUseAiTools) {
      error = '当前服务端不可用，暂时无法解释页面';
      statusMessage = '页面解释不可用';
      notifyListeners();
      return;
    }

    isExplaining = true;
    error = null;
    notifyListeners();

    try {
      final explanation = await repository.explainPage(document.definition);
      lastExplanation = explanation;
      statusMessage = '页面结构说明已生成';
    } catch (explainError) {
      error = explainError.toString();
      statusMessage = '页面解释失败';
    } finally {
      isExplaining = false;
      notifyListeners();
    }
  }

  Future<void> validateCurrentPage({
    bool showStatus = true,
    bool replaceWithNormalized = false,
  }) async {
    final document = currentDocument;
    if (document == null) {
      validationResult = null;
      return;
    }

    if (!canUseAiTools) {
      validationResult = null;
      return;
    }

    isValidating = true;
    notifyListeners();

    try {
      final result = await repository.validatePage(document.definition);
      validationResult = result;

      if (replaceWithNormalized && result.valid) {
        currentDocument = document.copyWith(
          definition: _cloneMap(result.normalizedDefinition),
        );
        _bumpSource();
      }

      if (showStatus) {
        if (result.valid && result.warnings.isEmpty) {
          statusMessage = '页面结构校验通过';
        } else if (result.valid) {
          statusMessage = '页面可渲染，但有 ${result.warnings.length} 条提示';
        } else {
          statusMessage = '页面校验失败：${result.errors.length} 个错误';
        }
      }
    } catch (validationError) {
      validationResult = null;
      error = validationError.toString();
      if (showStatus) {
        statusMessage = '页面校验失败';
      }
    } finally {
      isValidating = false;
      notifyListeners();
    }
  }

  Future<void> clearDraft() async {
    final slug = selectedSlug;
    if (slug == null) {
      return;
    }
    await draftStore.deleteDraft(slug);
    draftUpdatedAt = null;
    statusMessage = '已清空本地草稿';
    notifyListeners();
  }

  Future<SaveResultModel> persistCurrentPage({
    Map<String, dynamic>? overrides,
  }) async {
    final document = currentDocument;
    if (document == null) {
      throw Exception('当前没有可固化的页面');
    }

    isSaving = true;
    error = null;
    notifyListeners();

    try {
      final saveResult = await repository.savePage(
        slug: (overrides?['slug'] as String?) ?? document.slug,
        title: (overrides?['title'] as String?) ?? document.title,
        description:
            (overrides?['description'] as String?) ?? document.description,
        note: (overrides?['note'] as String?) ?? 'Saved from studio',
        author: 'studio-user',
        definition: _cloneMap(document.definition),
      );

      currentDocument = saveResult.page.copyWith(
        definition: _cloneMap(document.definition),
      );
      selectedVersion = saveResult.page.version;
      selectedSlug = saveResult.page.slug;
      statusMessage = '固化完成：${saveResult.versionUri}';
      await draftStore.deleteDraft(saveResult.page.slug);
      draftUpdatedAt = null;
      await refreshPages();
      await loadPage(
        saveResult.page.slug,
        version: saveResult.page.version,
        preserveAppContext: currentAppDocument != null,
      );
      return saveResult;
    } catch (saveError) {
      error = saveError.toString();
      statusMessage = '固化失败';
      rethrow;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> invokeRuntimeTool(
    String toolName,
    Map<String, dynamic> params,
  ) async {
    if (toolName == 'persistPage') {
      final result = await persistCurrentPage(overrides: params);
      return <String, dynamic>{
        'success': true,
        'result': <String, dynamic>{
          'slug': result.page.slug,
          'version': result.page.version,
          'stableUri': result.stableUri,
          'versionUri': result.versionUri,
        },
        'message': '页面已固化',
      };
    }

    final response = await repository.invokeTool(toolName, params);
    if (response['success'] == true) {
      return response;
    }
    return <String, dynamic>{
      'success': false,
      'error': response['error'] ?? 'Tool invocation failed',
    };
  }

  String describeBlock(Map<String, dynamic> block, int index) {
    final type = block['type']?.toString() ?? 'unknown';
    final title =
        block['title']?.toString() ?? block['label']?.toString() ?? type;
    return '${index + 1}. $title';
  }

  Future<void> _persistDraft() async {
    final document = currentDocument;
    if (document == null) {
      return;
    }
    await draftStore.saveDraft(document.slug, document.definition);
    draftUpdatedAt = draftStore.readDraftUpdatedAt(document.slug);
  }

  void _bumpSource() {
    sourceRevision += 1;
  }

  void _bumpAppSource() {
    appSourceRevision += 1;
  }

  AppDocumentModel _syncAppDocumentFromSchema(AppDocumentModel document) {
    return document.copyWith(
      appId: _schemaString(document.schema, 'appId') ?? document.appId,
      slug: _schemaString(document.schema, 'slug') ?? document.slug,
      name: _schemaString(document.schema, 'name') ?? document.name,
      description:
          _schemaString(document.schema, 'description') ?? document.description,
    );
  }

  String? _schemaString(Map<String, dynamic> schema, String key) {
    final value = schema[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  Future<void> _loadInitialAppRoute(AppDocumentModel document) async {
    final routes = _extractRoutesFromSchema(document.schema);
    if (routes.isEmpty) {
      activeAppRoute = null;
      return;
    }

    final homePage = document.schema['homePage']?.toString();
    Map<String, dynamic>? targetRoute;
    if (homePage != null && homePage.isNotEmpty) {
      for (final route in routes) {
        if (route['pageSlug']?.toString() == homePage) {
          targetRoute = route;
          break;
        }
      }
    }
    targetRoute ??= routes.first;

    final targetPath = targetRoute['path']?.toString();
    final targetPageSlug = targetRoute['pageSlug']?.toString();
    if (targetPath == null ||
        targetPath.isEmpty ||
        targetPageSlug == null ||
        targetPageSlug.isEmpty) {
      activeAppRoute = null;
      return;
    }

    activeAppRoute = targetPath;
    await loadPage(targetPageSlug, preserveAppContext: true);
  }

  List<Map<String, dynamic>> _extractRoutesFromSchema(
      Map<String, dynamic> schema) {
    final routes = schema['routes'];
    if (routes is! List) {
      return const <Map<String, dynamic>>[];
    }
    return routes
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<dynamic> _editableChildren() {
    final definition = currentDocument?.definition;
    if (definition == null) {
      throw StateError('Current document is not loaded');
    }

    final content = definition.putIfAbsent(
      'content',
      () => <String, dynamic>{
        'type': 'linear',
        'direction': 'vertical',
        'gap': 16,
        'children': <dynamic>[],
      },
    ) as Map<String, dynamic>;

    content['type'] ??= 'linear';
    content['direction'] ??= 'vertical';
    content['gap'] ??= 16;
    final children =
        content.putIfAbsent('children', () => <dynamic>[]) as List<dynamic>;
    return children;
  }

  Map<String, dynamic> _buildSnippet(String kind) {
    switch (kind) {
      case 'kpi':
        return <String, dynamic>{
          'type': 'antdSection',
          'title': '新增 KPI 组',
          'subtitle': '拖动排序后即可保存为新版本',
          'metaId': _uuid.v4(),
          'child': <String, dynamic>{
            'type': 'linear',
            'direction': 'horizontal',
            'gap': 12,
            'wrap': true,
            'children': <dynamic>[
              <String, dynamic>{
                'type': 'antdStat',
                'title': '转化率',
                'value': '31.4',
                'suffix': '%',
                'trend': '+2.3%',
                'tone': 'teal'
              },
              <String, dynamic>{
                'type': 'antdStat',
                'title': '平均客单价',
                'value': '286',
                'suffix': '元',
                'trend': '+11',
                'tone': 'blue'
              }
            ]
          }
        };
      case 'table':
        return <String, dynamic>{
          'type': 'antdSection',
          'title': '新增表格块',
          'subtitle': '适合将 AI 工具返回的列表结构落入页面',
          'metaId': _uuid.v4(),
          'child': <String, dynamic>{
            'type': 'antdTable',
            'columns': <dynamic>[
              <String, dynamic>{'key': 'name', 'title': '名称'},
              <String, dynamic>{'key': 'owner', 'title': 'Owner'},
              <String, dynamic>{'key': 'status', 'title': '状态'}
            ],
            'rows': <dynamic>[
              <String, dynamic>{
                'name': '新建任务',
                'owner': '产品组',
                'status': 'healthy'
              }
            ]
          }
        };
      case 'toolbar':
        return <String, dynamic>{
          'type': 'antdSection',
          'title': '新增操作条',
          'subtitle': '按钮可直连 state/tool/resource action',
          'metaId': _uuid.v4(),
          'child': <String, dynamic>{
            'type': 'linear',
            'direction': 'horizontal',
            'gap': 12,
            'wrap': true,
            'children': <dynamic>[
              <String, dynamic>{
                'type': 'button',
                'label': '切换状态',
                'variant': 'outlined',
                'click': <String, dynamic>{
                  'type': 'state',
                  'action': 'set',
                  'binding': 'app.statusText',
                  'value': '已手动触发'
                }
              },
              <String, dynamic>{
                'type': 'button',
                'label': '固化',
                'variant': 'filled',
                'backgroundColor': '#0f766e',
                'click': <String, dynamic>{
                  'type': 'tool',
                  'tool': 'persistPage',
                  'params': <String, dynamic>{}
                }
              }
            ]
          }
        };
      default:
        return <String, dynamic>{
          'type': 'antdSection',
          'title': '新增说明块',
          'subtitle': '这里可以继续手工编辑 JSON 扩展能力',
          'metaId': _uuid.v4(),
          'child': <String, dynamic>{
            'type': 'text',
            'content': '这是一个可以继续细化的说明块。'
          }
        };
    }
  }

  Future<void> _loadAiMetadata() async {
    if (isUsingBundledFallback) {
      templates = _defaultTemplates();
      componentCatalog = <ComponentCatalogItemModel>[];
      return;
    }

    try {
      final results = await Future.wait(<Future<Object>>[
        repository.listTemplates(),
        repository.listComponents(),
      ]);
      templates = results[0] as List<PageTemplateModel>;
      componentCatalog = results[1] as List<ComponentCatalogItemModel>;
    } catch (_) {
      templates = _defaultTemplates();
      componentCatalog = <ComponentCatalogItemModel>[];
    }
  }

  List<PageTemplateModel> _defaultTemplates() {
    return <PageTemplateModel>[
      PageTemplateModel(
        slug: 'dashboard',
        title: 'Dashboard',
        description: 'KPI 概览仪表盘',
      ),
      PageTemplateModel(
        slug: 'form',
        title: 'Form',
        description: '数据录入表单',
      ),
      PageTemplateModel(
        slug: 'table',
        title: 'Table / List',
        description: '数据列表页',
      ),
    ];
  }

  Map<String, dynamic> _cloneMap(Map<String, dynamic> source) {
    return Map<String, dynamic>.from(
      jsonDecode(jsonEncode(source)) as Map<String, dynamic>,
    );
  }
}
