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

class PageTemplateModel {
  PageTemplateModel({
    required this.slug,
    required this.title,
    this.description,
  });

  final String slug;
  final String title;
  final String? description;

  factory PageTemplateModel.fromJson(Map<String, dynamic> json) {
    return PageTemplateModel(
      slug: json['slug'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
    );
  }
}

class ValidationIssueModel {
  ValidationIssueModel({
    required this.path,
    required this.message,
    this.suggestion,
  });

  final String path;
  final String message;
  final String? suggestion;

  factory ValidationIssueModel.fromJson(Map<String, dynamic> json) {
    return ValidationIssueModel(
      path: json['path'] as String? ?? '',
      message: json['message'] as String? ?? '',
      suggestion: json['suggestion'] as String?,
    );
  }
}

class PageValidationResultModel {
  PageValidationResultModel({
    required this.valid,
    required this.errors,
    required this.warnings,
    required this.normalizedDefinition,
    required this.usedComponents,
  });

  final bool valid;
  final List<ValidationIssueModel> errors;
  final List<ValidationIssueModel> warnings;
  final Map<String, dynamic> normalizedDefinition;
  final List<String> usedComponents;

  factory PageValidationResultModel.fromJson(Map<String, dynamic> json) {
    return PageValidationResultModel(
      valid: json['valid'] as bool? ?? false,
      errors: (json['errors'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (item) => ValidationIssueModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      warnings: (json['warnings'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (item) => ValidationIssueModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      normalizedDefinition: Map<String, dynamic>.from(
        json['normalizedDefinition'] as Map<String, dynamic>? ??
            <String, dynamic>{},
      ),
      usedComponents: (json['usedComponents'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class GeneratedPageResultModel {
  GeneratedPageResultModel({
    required this.slug,
    required this.title,
    required this.pageType,
    required this.definition,
    required this.summary,
    required this.warnings,
    required this.usedComponents,
    required this.assumptions,
    this.seedTemplate,
  });

  final String slug;
  final String title;
  final String pageType;
  final String? seedTemplate;
  final Map<String, dynamic> definition;
  final String summary;
  final List<String> warnings;
  final List<String> usedComponents;
  final List<String> assumptions;

  factory GeneratedPageResultModel.fromJson(Map<String, dynamic> json) {
    return GeneratedPageResultModel(
      slug: json['slug'] as String,
      title: json['title'] as String,
      pageType: json['pageType'] as String? ?? 'dashboard',
      seedTemplate: json['seedTemplate'] as String?,
      definition: Map<String, dynamic>.from(
        json['definition'] as Map<String, dynamic>,
      ),
      summary: json['summary'] as String? ?? '',
      warnings: (json['warnings'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      usedComponents: (json['usedComponents'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      assumptions: (json['assumptions'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class ComponentPropModel {
  ComponentPropModel({
    required this.name,
    required this.type,
    required this.description,
    this.required = false,
  });

  final String name;
  final String type;
  final String description;
  final bool required;

  factory ComponentPropModel.fromJson(Map<String, dynamic> json) {
    return ComponentPropModel(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      required: json['required'] as bool? ?? false,
    );
  }
}

class ComponentCatalogItemModel {
  ComponentCatalogItemModel({
    required this.name,
    required this.category,
    required this.description,
    required this.props,
    required this.sample,
    required this.recommendedForAi,
  });

  final String name;
  final String category;
  final String description;
  final List<ComponentPropModel> props;
  final Map<String, dynamic> sample;
  final bool recommendedForAi;

  factory ComponentCatalogItemModel.fromJson(Map<String, dynamic> json) {
    return ComponentCatalogItemModel(
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      props: (json['props'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (item) => ComponentPropModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      sample: Map<String, dynamic>.from(
        json['sample'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      recommendedForAi: json['recommendedForAi'] as bool? ?? false,
    );
  }
}
