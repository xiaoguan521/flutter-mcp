class PageSummaryModel {
  PageSummaryModel({
    required this.slug,
    required this.title,
    required this.stableVersion,
    required this.updatedAt,
    required this.stableUri,
    required this.versionUri,
    this.description,
  });

  final String slug;
  final String title;
  final String stableVersion;
  final String updatedAt;
  final String stableUri;
  final String versionUri;
  final String? description;

  factory PageSummaryModel.fromJson(Map<String, dynamic> json) {
    return PageSummaryModel(
      slug: json['slug'] as String,
      title: json['title'] as String,
      stableVersion: json['stableVersion'] as String? ?? 'stable',
      updatedAt: json['updatedAt'] as String? ?? '',
      stableUri: json['stableUri'] as String? ?? '',
      versionUri: json['versionUri'] as String? ?? '',
      description: json['description'] as String?,
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
  final Map<String, dynamic> definition;

  factory PageDocumentModel.fromJson(Map<String, dynamic> json) {
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
      isStable: json['isStable'] as bool? ?? false,
      definition: Map<String, dynamic>.from(
        json['definition'] as Map<String, dynamic>,
      ),
    );
  }
}
