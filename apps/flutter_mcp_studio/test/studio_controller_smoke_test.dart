import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mcp_studio/core/models/page_models.dart';
import 'package:flutter_mcp_studio/core/services/mcp_bridge_service.dart';
import 'package:flutter_mcp_studio/core/services/page_repository.dart';
import 'package:flutter_mcp_studio/features/editor/studio_controller.dart';
import 'package:flutter_mcp_studio/features/persistence/local_draft_store.dart';

void main() {
  test('StudioController can generate, refine, validate, and persist a page',
      () async {
    final repository = _FakePageRepository();
    final draftStore = _FakeLocalDraftStore();
    final mcpBridge = _FakeMcpBridgeService();
    final controller = StudioController(
      repository: repository,
      draftStore: draftStore,
      mcpBridgeService: mcpBridge,
    );

    await controller.generatePageFromPrompt(
      prompt: '帮我生成一个客户列表页，包含搜索、状态筛选和操作按钮',
      pageType: 'table-list',
    );

    expect(controller.currentDocument, isNotNull);
    expect(controller.currentDocument!.slug, 'ai-customer-list');
    expect(controller.validationResult?.valid, isTrue);
    expect(controller.lastGeneration?.pageType, 'table-list');
    expect(draftStore.hasDraft('ai-customer-list'), isTrue);

    await controller.updateCurrentPageByInstruction(
      instruction: '把标题改成客户运营列表，并增加搜索筛选和操作按钮',
    );

    expect(controller.currentDocument?.title, '客户运营列表');
    expect(controller.lastInstructionUpdate, isNotNull);
    expect(controller.lastInstructionUpdate!.appliedChanges, isNotEmpty);
    expect(controller.validationResult?.valid, isTrue);

    await controller.explainCurrentPage();

    expect(controller.lastExplanation, isNotNull);
    expect(controller.lastExplanation!.pageType, 'table-list');
    expect(controller.lastExplanation!.usedComponents, isNotEmpty);
    expect(
      controller.lastExplanation!.actionSummary.any(
        (item) => item.contains('persistPage'),
      ),
      isTrue,
    );

    final saveResult = await controller.persistCurrentPage();

    expect(saveResult.page.slug, 'ai-customer-list');
    expect(saveResult.page.version, 'v1');
    expect(controller.selectedVersion, 'v1');
    expect(controller.pages, isNotEmpty);
    expect(controller.versions, isNotEmpty);
    expect(draftStore.hasDraft('ai-customer-list'), isFalse);
    expect(controller.validationResult?.valid, isTrue);
  });
}

class _FakePageRepository extends PageRepository {
  _FakePageRepository() : super(baseUrl: 'http://localhost:8787');

  final Map<String, PageDocumentModel> _pages = <String, PageDocumentModel>{};
  final Map<String, List<PageVersionModel>> _versions =
      <String, List<PageVersionModel>>{};
  int _versionCounter = 0;

  @override
  Future<GeneratedPageResultModel> generatePageFromPrompt({
    required String prompt,
    required String pageType,
    String? seedTemplate,
    String? locale,
  }) async {
    return GeneratedPageResultModel(
      slug: 'ai-customer-list',
      title: 'Customer List',
      pageType: pageType,
      definition: _buildBaseDefinition(title: 'Customer List'),
      summary: 'Generated a customer list page.',
      warnings: const <String>[],
      usedComponents: const <String>[
        'page',
        'linear',
        'searchBar',
        'antdSection',
        'antdTable',
        'button',
        'select',
      ],
      assumptions: const <String>[
        'Used the table/list preset.',
      ],
    );
  }

  @override
  Future<PageUpdateResultModel> updatePageByInstruction({
    required Map<String, dynamic> definition,
    required String instruction,
    String? locale,
  }) async {
    final updated = _clone(definition);
    updated['title'] = '客户运营列表';

    final content = Map<String, dynamic>.from(updated['content'] as Map);
    final children = List<dynamic>.from(content['children'] as List<dynamic>);
    children.insert(
      0,
      <String, dynamic>{
        'type': 'searchBar',
        'label': 'Search',
        'binding': 'app.filters.keyword',
        'placeholder': 'Search customer',
        'buttonLabel': 'Apply',
        'searchAction': <String, dynamic>{
          'type': 'state',
          'action': 'set',
          'binding': 'app.statusText',
          'value': 'Filters applied',
        },
        'filters': <dynamic>[
          <String, dynamic>{
            'type': 'select',
            'label': 'Status',
            'binding': 'app.filters.status',
            'items': <dynamic>[
              <String, dynamic>{'value': 'all', 'label': 'All'},
              <String, dynamic>{'value': 'healthy', 'label': 'Healthy'},
            ],
          },
        ],
      },
    );
    content['children'] = children;
    updated['content'] = content;

    return PageUpdateResultModel(
      title: '客户运营列表',
      definition: updated,
      summary: 'Applied 3 AI refinement changes.',
      warnings: const <String>[],
      usedComponents: const <String>[
        'page',
        'linear',
        'searchBar',
        'select',
        'antdSection',
        'antdTable',
        'button',
      ],
      assumptions: const <String>[
        'Applied rule-based list refinements.',
      ],
      appliedChanges: const <String>[
        'Updated the page title.',
        'Added search and filter controls.',
        'Added an action toolbar section.',
      ],
    );
  }

  @override
  Future<PageValidationResultModel> validatePage(
    Map<String, dynamic> definition,
  ) async {
    return PageValidationResultModel(
      valid: true,
      errors: const <ValidationIssueModel>[],
      warnings: const <ValidationIssueModel>[],
      normalizedDefinition: _clone(definition),
      usedComponents: _collectTypes(definition).toList()..sort(),
    );
  }

  @override
  Future<PageExplanationResultModel> explainPage(
    Map<String, dynamic> definition,
  ) async {
    return PageExplanationResultModel(
      summary: 'This table/list page has searchable rows and save actions.',
      pageType: 'table-list',
      structure: const <String>[
        '- linear',
        '  - searchBar (Search)',
        '  - antdSection (Customer Table)',
      ],
      usedComponents: _collectTypes(definition).toList()..sort(),
      actionSummary: const <String>[
        'page.content.children[0].searchAction: state -> app.statusText',
        'page.content.children[1].child.children[0].click: tool -> persistPage',
      ],
      bindingSummary: const <String>[
        'app.filters.keyword',
        'app.statusText',
        'app.rows',
      ],
      warnings: const <String>[],
    );
  }

  @override
  Future<SaveResultModel> savePage({
    required String slug,
    required String title,
    String? description,
    String? note,
    String? author,
    bool makeStable = true,
    required Map<String, dynamic> definition,
  }) async {
    _versionCounter += 1;
    final version = 'v$_versionCounter';
    final page = PageDocumentModel(
      slug: slug,
      title: title,
      description: description,
      version: version,
      author: author ?? 'studio-user',
      note: note,
      stableUri: 'mcpui://pages/$slug/stable',
      versionUri: 'mcpui://pages/$slug/versions/$version',
      createdAt: '2026-04-03T20:00:00.000Z',
      updatedAt: '2026-04-03T20:00:00.000Z',
      isStable: makeStable,
      definition: _clone(definition),
    );
    _pages[slug] = page;
    _versions[slug] = <PageVersionModel>[
      PageVersionModel(
        slug: slug,
        title: title,
        version: version,
        createdAt: '2026-04-03T20:00:00.000Z',
        isStable: makeStable,
        author: author ?? 'studio-user',
        stableUri: 'mcpui://pages/$slug/stable',
        versionUri: 'mcpui://pages/$slug/versions/$version',
        note: note,
      ),
    ];

    return SaveResultModel(
      page: page,
      stableUri: page.stableUri!,
      versionUri: page.versionUri!,
    );
  }

  @override
  Future<List<PageSummaryModel>> listPages() async {
    return _pages.values
        .map(
          (page) => PageSummaryModel(
            slug: page.slug,
            title: page.title,
            description: page.description,
            stableVersion: page.version ?? 'v0',
            updatedAt: page.updatedAt ?? '',
            stableUri: page.stableUri ?? '',
            versionUri: page.versionUri ?? '',
          ),
        )
        .toList();
  }

  @override
  Future<PageDocumentModel> loadPage(
    String slug, {
    String? version,
  }) async {
    return _pages[slug]!;
  }

  @override
  Future<List<PageVersionModel>> listVersions(String slug) async {
    return _versions[slug] ?? <PageVersionModel>[];
  }

  Map<String, dynamic> _buildBaseDefinition({required String title}) {
    return <String, dynamic>{
      'type': 'page',
      'title': title,
      'state': <String, dynamic>{
        'initial': <String, dynamic>{
          'rows': <dynamic>[
            <String, dynamic>{
              'name': 'Northwind Retail',
              'owner': 'Ava Chen',
              'status': 'healthy',
            },
          ],
          'filters': <String, dynamic>{
            'keyword': '',
            'status': 'all',
          },
          'statusText': 'Draft',
        },
      },
      'content': <String, dynamic>{
        'type': 'linear',
        'direction': 'vertical',
        'gap': 16,
        'children': <dynamic>[
          <String, dynamic>{
            'type': 'antdSection',
            'title': 'Customer Table',
            'child': <String, dynamic>{
              'type': 'antdTable',
              'columns': <dynamic>[
                <String, dynamic>{'key': 'name', 'title': 'Name'},
                <String, dynamic>{'key': 'owner', 'title': 'Owner'},
                <String, dynamic>{'key': 'status', 'title': 'Status'},
              ],
              'rows': <String, dynamic>{'binding': 'app.rows'},
            },
          },
          <String, dynamic>{
            'type': 'antdSection',
            'title': 'Actions',
            'child': <String, dynamic>{
              'type': 'linear',
              'direction': 'horizontal',
              'gap': 12,
              'children': <dynamic>[
                <String, dynamic>{
                  'type': 'button',
                  'label': 'Save page',
                  'click': <String, dynamic>{
                    'type': 'tool',
                    'tool': 'persistPage',
                    'params': <String, dynamic>{},
                  },
                },
              ],
            },
          },
        ],
      },
    };
  }

  Map<String, dynamic> _clone(Map<String, dynamic> value) {
    return Map<String, dynamic>.from(
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>,
    );
  }

  Set<String> _collectTypes(Map<String, dynamic> definition) {
    final types = <String>{};

    void walk(dynamic node) {
      if (node is Map) {
        final map = Map<String, dynamic>.from(node);
        final type = map['type']?.toString();
        if (type != null && type.isNotEmpty) {
          types.add(type);
        }
        for (final value in map.values) {
          walk(value);
        }
      } else if (node is List) {
        for (final item in node) {
          walk(item);
        }
      }
    }

    walk(definition);
    return types;
  }
}

class _FakeLocalDraftStore extends LocalDraftStore {
  final Map<String, Map<String, dynamic>> _drafts =
      <String, Map<String, dynamic>>{};
  final Map<String, String> _updatedAt = <String, String>{};

  @override
  Future<void> saveDraft(String slug, Map<String, dynamic> definition) async {
    _drafts[slug] = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(definition)) as Map<String, dynamic>,
    );
    _updatedAt[slug] = '2026-04-03T20:00:00.000Z';
  }

  @override
  Map<String, dynamic>? readDraft(String slug) => _drafts[slug];

  @override
  String? readDraftUpdatedAt(String slug) => _updatedAt[slug];

  @override
  Future<void> deleteDraft(String slug) async {
    _drafts.remove(slug);
    _updatedAt.remove(slug);
  }

  @override
  bool hasDraft(String slug) => _drafts.containsKey(slug);
}

class _FakeMcpBridgeService extends McpBridgeService {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> ensureConnected({String? baseUrl}) async => true;
}
