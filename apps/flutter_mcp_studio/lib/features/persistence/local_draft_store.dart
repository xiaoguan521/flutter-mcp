import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

class LocalDraftStore {
  static const String _boxName = 'page_drafts';
  static const String _metaBoxName = 'page_draft_meta';

  late final Box<String> _draftBox;
  late final Box<String> _metaBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _draftBox = await Hive.openBox<String>(_boxName);
    _metaBox = await Hive.openBox<String>(_metaBoxName);
  }

  Future<void> saveDraft(String slug, Map<String, dynamic> definition) async {
    await _draftBox.put(slug, jsonEncode(definition));
    await _metaBox.put(slug, DateTime.now().toIso8601String());
  }

  Map<String, dynamic>? readDraft(String slug) {
    final raw = _draftBox.get(slug);
    if (raw == null) {
      return null;
    }
    return Map<String, dynamic>.from(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  String? readDraftUpdatedAt(String slug) {
    return _metaBox.get(slug);
  }

  Future<void> deleteDraft(String slug) async {
    await _draftBox.delete(slug);
    await _metaBox.delete(slug);
  }

  bool hasDraft(String slug) => _draftBox.containsKey(slug);
}

