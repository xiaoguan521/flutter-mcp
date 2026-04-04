import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/page_models.dart';

class PageRepository {
  PageRepository({http.Client? client, required this.baseUrl})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  Future<List<PageSummaryModel>> listPages() async {
    final response = await _client.get(_uri('/api/pages'));
    final body = _decodeBody(response);
    final result = body['result'] as List<dynamic>;
    return result
        .map(
          (item) =>
              PageSummaryModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<PageDocumentModel> loadPage(String slug, {String? version}) async {
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

  Future<PageDocumentModel> resolvePageUri(String uri) async {
    final response = await _client.get(
      _uri('/api/resources/resolve', <String, String>{'uri': uri}),
    );
    final body = _decodeBody(response);
    final result = Map<String, dynamic>.from(body['result'] as Map);
    if (!result.containsKey('definition')) {
      throw Exception('Resource is not a page snapshot: $uri');
    }
    return PageDocumentModel.fromJson(result);
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

  void close() {
    _client.close();
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400 || decoded['success'] == false) {
      throw Exception(decoded['error'] ?? 'Unexpected server error');
    }
    return decoded;
  }
}
