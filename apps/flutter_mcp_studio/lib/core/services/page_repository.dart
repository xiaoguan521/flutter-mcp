import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/page_models.dart';

const String kDefaultServerUrl = String.fromEnvironment(
  'MCP_UI_SERVER_URL',
  defaultValue: 'http://127.0.0.1:8787',
);

class PageRepository {
  PageRepository({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? kDefaultServerUrl;

  final http.Client _client;
  final String baseUrl;

  static const List<String> bundledSampleAssets = <String>[
    'assets/samples/dashboard.page.json',
    'assets/samples/form.page.json',
    'assets/samples/table.page.json',
  ];

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  Future<List<PageSummaryModel>> listPages() async {
    final response = await _client.get(_uri('/api/pages'));
    final body = _decodeBody(response);
    final result = body['result'] as List<dynamic>;
    return result
        .map((item) => PageSummaryModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }

  Future<List<AppSummaryModel>> listApps() async {
    final response = await _client.get(_uri('/api/apps'));
    final body = _decodeBody(response);
    final result = body['result'] as List<dynamic>;
    return result
        .map((item) => AppSummaryModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }

  Future<List<PageTemplateModel>> listTemplates() async {
    final response = await _client.get(_uri('/api/templates'));
    final body = _decodeBody(response);
    final result = body['result'] as List<dynamic>;
    return result
        .map((item) => PageTemplateModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }

  Future<PageDocumentModel> loadPage(
    String slug, {
    String? version,
  }) async {
    final response = await _client.get(
      _uri(
        '/api/pages/$slug',
        version == null ? null : <String, String>{'version': version},
      ),
    );
    final body = _decodeBody(response);
    return PageDocumentModel.fromJson(
      Map<String, dynamic>.from(body['result'] as Map),
    );
  }

  Future<AppDocumentModel> loadApp(
    String slug, {
    String? version,
  }) async {
    final response = await _client.get(
      _uri(
        '/api/apps/$slug',
        version == null ? null : <String, String>{'version': version},
      ),
    );
    final body = _decodeBody(response);
    return AppDocumentModel.fromJson(
      Map<String, dynamic>.from(body['result'] as Map),
    );
  }

  Future<List<PageVersionModel>> listVersions(String slug) async {
    final response = await _client.get(_uri('/api/pages/$slug/versions'));
    final body = _decodeBody(response);
    final result = body['result'] as List<dynamic>;
    return result
        .map((item) => PageVersionModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }

  Future<List<AppVersionModel>> listAppVersions(String slug) async {
    final response = await _client.get(_uri('/api/apps/$slug/versions'));
    final body = _decodeBody(response);
    final result = body['result'] as List<dynamic>;
    return result
        .map((item) => AppVersionModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }

  Future<SaveResultModel> savePage({
    required String slug,
    required String title,
    String? description,
    String? note,
    String? author,
    bool makeStable = true,
    required Map<String, dynamic> definition,
  }) async {
    final response = await _client.post(
      _uri('/api/pages/$slug/save'),
      headers: <String, String>{'content-type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'title': title,
        'description': description,
        'note': note,
        'author': author,
        'makeStable': makeStable,
        'definition': definition,
      }),
    );
    final body = _decodeBody(response);
    return SaveResultModel.fromJson(
      Map<String, dynamic>.from(body['result'] as Map),
    );
  }

  Future<SaveAppResultModel> saveApp({
    required String slug,
    required String name,
    String? description,
    String? note,
    String? author,
    bool makeStable = true,
    required Map<String, dynamic> schema,
  }) async {
    final response = await _client.post(
      _uri('/api/apps/$slug/save'),
      headers: <String, String>{'content-type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'name': name,
        'description': description,
        'note': note,
        'author': author,
        'makeStable': makeStable,
        'schema': schema,
      }),
    );
    final body = _decodeBody(response);
    return SaveAppResultModel.fromJson(
      Map<String, dynamic>.from(body['result'] as Map),
    );
  }

  Future<CreateAppResultModel> createApp({
    required String name,
    String? slug,
    String? description,
    List<String>? pageSlugs,
    String? navigationStyle,
    String? author,
  }) async {
    final response = await _client.post(
      _uri('/api/tools/create_app'),
      headers: <String, String>{'content-type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'name': name,
        if (slug != null && slug.isNotEmpty) 'slug': slug,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (pageSlugs != null && pageSlugs.isNotEmpty) 'pageSlugs': pageSlugs,
        if (navigationStyle != null && navigationStyle.isNotEmpty)
          'navigationStyle': navigationStyle,
        if (author != null && author.isNotEmpty) 'author': author,
      }),
    );
    final body = _decodeBody(response);
    return CreateAppResultModel.fromJson(
      Map<String, dynamic>.from(body['result'] as Map),
    );
  }

  Future<GeneratedPageResultModel> generatePageFromPrompt({
    required String prompt,
    required String pageType,
    String? seedTemplate,
    String? locale,
  }) async {
    final response = await _client.post(
      _uri('/api/tools/generate_page_from_prompt'),
      headers: <String, String>{'content-type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'prompt': prompt,
        'pageType': pageType,
        if (seedTemplate != null && seedTemplate.isNotEmpty)
          'seedTemplate': seedTemplate,
        if (locale != null && locale.isNotEmpty) 'locale': locale,
      }),
    );
    final body = _decodeBody(response);
    return GeneratedPageResultModel.fromJson(
      Map<String, dynamic>.from(body['result'] as Map),
    );
  }

  Future<PageValidationResultModel> validatePage(
    Map<String, dynamic> definition,
  ) async {
    final response = await _client.post(
      _uri('/api/tools/validate_page'),
      headers: <String, String>{'content-type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'definition': definition,
      }),
    );
    final body = _decodeBody(response);
    return PageValidationResultModel.fromJson(
      Map<String, dynamic>.from(body['result'] as Map),
    );
  }

  Future<AppValidationResultModel> validateApp(
    Map<String, dynamic> schema,
  ) async {
    final response = await _client.post(
      _uri('/api/tools/validate_app'),
      headers: <String, String>{'content-type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'schema': schema,
      }),
    );
    final body = _decodeBody(response);
    return AppValidationResultModel.fromJson(
      Map<String, dynamic>.from(body['result'] as Map),
    );
  }

  Future<PageExplanationResultModel> explainPage(
    Map<String, dynamic> definition,
  ) async {
    final response = await _client.post(
      _uri('/api/tools/explain_page'),
      headers: <String, String>{'content-type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'definition': definition,
      }),
    );
    final body = _decodeBody(response);
    return PageExplanationResultModel.fromJson(
      Map<String, dynamic>.from(body['result'] as Map),
    );
  }

  Future<PageUpdateResultModel> updatePageByInstruction({
    required Map<String, dynamic> definition,
    required String instruction,
    String? locale,
  }) async {
    final response = await _client.post(
      _uri('/api/tools/update_page_by_instruction'),
      headers: <String, String>{'content-type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'definition': definition,
        'instruction': instruction,
        if (locale != null && locale.isNotEmpty) 'locale': locale,
      }),
    );
    final body = _decodeBody(response);
    return PageUpdateResultModel.fromJson(
      Map<String, dynamic>.from(body['result'] as Map),
    );
  }

  Future<List<ComponentCatalogItemModel>> listComponents({
    bool recommendedOnly = false,
  }) async {
    final response = await _client.post(
      _uri('/api/tools/list_components'),
      headers: <String, String>{'content-type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'recommendedOnly': recommendedOnly,
      }),
    );
    final body = _decodeBody(response);
    final result = body['result'] as List<dynamic>;
    return result
        .map((item) => ComponentCatalogItemModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }

  Future<Map<String, dynamic>> invokeTool(
    String toolName,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.post(
      _uri('/api/tools/$toolName'),
      headers: <String, String>{'content-type': 'application/json'},
      body: jsonEncode(payload),
    );
    return _decodeBody(response);
  }

  Future<List<PageSummaryModel>> loadBundledPageSummaries() async {
    final pages = await loadBundledPageDocuments();
    return pages
        .map(
          (page) => PageSummaryModel(
            slug: page.slug,
            title: page.title,
            description: page.description,
            stableVersion: page.version ?? 'bundled',
            updatedAt: page.updatedAt ?? '',
            stableUri: page.stableUri ?? '',
            versionUri: page.versionUri ?? '',
            isBundled: true,
          ),
        )
        .toList();
  }

  Future<List<PageDocumentModel>> loadBundledPageDocuments() async {
    final documents = <PageDocumentModel>[];
    for (final asset in bundledSampleAssets) {
      final raw = await rootBundle.loadString(asset);
      final json = Map<String, dynamic>.from(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      documents.add(PageDocumentModel.fromJson(json, isBundled: true));
    }
    return documents;
  }

  Future<PageDocumentModel?> loadBundledPage(String slug) async {
    final pages = await loadBundledPageDocuments();
    for (final page in pages) {
      if (page.slug == slug) {
        return page;
      }
    }
    return null;
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400 || decoded['success'] == false) {
      throw Exception(decoded['error'] ?? 'Unexpected server error');
    }
    return decoded;
  }
}
