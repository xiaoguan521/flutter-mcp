class PageSummaryModel {
  PageSummaryModel({
    required this.slug,
    required this.title,
    required this.stableVersion,
    required this.updatedAt,
    required this.stableUri,
    required this.versionUri,
    this.description,
    this.isBundled = false,
  });

  final String slug;
  final String title;
  final String stableVersion;
  final String updatedAt;
  final String stableUri;
  final String versionUri;
  final String? description;
  final bool isBundled;

  factory PageSummaryModel.fromJson(
    Map<String, dynamic> json, {
    bool isBundled = false,
  }) {
    return PageSummaryModel(
      slug: json['slug'] as String,
      title: json['title'] as String,
      stableVersion: json['stableVersion'] as String? ?? 'bundled',
      updatedAt: json['updatedAt'] as String? ?? '',
      stableUri: json['stableUri'] as String? ?? '',
      versionUri: json['versionUri'] as String? ?? '',
      description: json['description'] as String?,
      isBundled: isBundled,
    );
  }
}

class PageVersionModel {
  PageVersionModel({
    required this.slug,
    required this.title,
    required this.version,
    required this.createdAt,
    required this.isStable,
    required this.author,
    required this.stableUri,
    required this.versionUri,
    this.note,
  });

  final String slug;
  final String title;
  final String version;
  final String createdAt;
  final bool isStable;
  final String author;
  final String stableUri;
  final String versionUri;
  final String? note;

  factory PageVersionModel.fromJson(Map<String, dynamic> json) {
    return PageVersionModel(
      slug: json['slug'] as String,
      title: json['title'] as String,
      version: json['version'] as String,
      createdAt: json['createdAt'] as String,
      isStable: json['isStable'] as bool? ?? false,
      author: json['author'] as String? ?? 'unknown',
      stableUri: json['stableUri'] as String? ?? '',
      versionUri: json['versionUri'] as String? ?? '',
      note: json['note'] as String?,
    );
  }
}

class PageDocumentModel {
  PageDocumentModel({
    required this.slug,
    required this.title,
    required this.definition,
    this.description,
    this.version,
    this.author,
    this.note,
    this.stableUri,
    this.versionUri,
    this.createdAt,
    this.updatedAt,
    this.isStable = false,
    this.isBundled = false,
  });

  final String slug;
  final String title;
  final String? description;
  final String? version;
  final String? author;
  final String? note;
  final String? stableUri;
  final String? versionUri;
  final String? createdAt;
  final String? updatedAt;
  final bool isStable;
  final bool isBundled;
  final Map<String, dynamic> definition;

  factory PageDocumentModel.fromJson(
    Map<String, dynamic> json, {
    bool isBundled = false,
  }) {
    return PageDocumentModel(
      slug: json['slug'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      version: json['version'] as String?,
      author: json['author'] as String?,
      note: json['note'] as String?,
      stableUri: json['stableUri'] as String?,
      versionUri: json['versionUri'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      isStable: json['isStable'] as bool? ?? isBundled,
      isBundled: isBundled,
      definition: Map<String, dynamic>.from(
        json['definition'] as Map<String, dynamic>,
      ),
    );
  }

  PageDocumentModel copyWith({
    String? slug,
    String? title,
    String? description,
    String? version,
    String? author,
    String? note,
    String? stableUri,
    String? versionUri,
    String? createdAt,
    String? updatedAt,
    bool? isStable,
    bool? isBundled,
    Map<String, dynamic>? definition,
  }) {
    return PageDocumentModel(
      slug: slug ?? this.slug,
      title: title ?? this.title,
      description: description ?? this.description,
      version: version ?? this.version,
      author: author ?? this.author,
      note: note ?? this.note,
      stableUri: stableUri ?? this.stableUri,
      versionUri: versionUri ?? this.versionUri,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isStable: isStable ?? this.isStable,
      isBundled: isBundled ?? this.isBundled,
      definition: definition ?? this.definition,
    );
  }
}

class SaveResultModel {
  SaveResultModel({
    required this.page,
    required this.stableUri,
    required this.versionUri,
  });

  final PageDocumentModel page;
  final String stableUri;
  final String versionUri;

  factory SaveResultModel.fromJson(Map<String, dynamic> json) {
    return SaveResultModel(
      page: PageDocumentModel.fromJson(
        Map<String, dynamic>.from(json['page'] as Map<String, dynamic>),
      ),
      stableUri: json['stableUri'] as String,
      versionUri: json['versionUri'] as String,
    );
  }
}

