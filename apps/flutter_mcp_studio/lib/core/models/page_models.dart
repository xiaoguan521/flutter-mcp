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

class AppSummaryModel {
  AppSummaryModel({
    required this.slug,
    required this.name,
    required this.stableVersion,
    required this.updatedAt,
    required this.stableUri,
    required this.versionUri,
    this.description,
    this.homePage,
  });

  final String slug;
  final String name;
  final String stableVersion;
  final String updatedAt;
  final String stableUri;
  final String versionUri;
  final String? description;
  final String? homePage;

  factory AppSummaryModel.fromJson(Map<String, dynamic> json) {
    return AppSummaryModel(
      slug: json['slug'] as String,
      name: json['name'] as String,
      stableVersion: json['stableVersion'] as String? ?? 'v1',
      updatedAt: json['updatedAt'] as String? ?? '',
      stableUri: json['stableUri'] as String? ?? '',
      versionUri: json['versionUri'] as String? ?? '',
      description: json['description'] as String?,
      homePage: json['homePage'] as String?,
    );
  }
}

class AppVersionModel {
  AppVersionModel({
    required this.slug,
    required this.name,
    required this.version,
    required this.createdAt,
    required this.isStable,
    required this.author,
    required this.stableUri,
    required this.versionUri,
    this.note,
  });

  final String slug;
  final String name;
  final String version;
  final String createdAt;
  final bool isStable;
  final String author;
  final String stableUri;
  final String versionUri;
  final String? note;

  factory AppVersionModel.fromJson(Map<String, dynamic> json) {
    return AppVersionModel(
      slug: json['slug'] as String,
      name: json['name'] as String,
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

class AppDocumentModel {
  AppDocumentModel({
    required this.appId,
    required this.slug,
    required this.name,
    required this.schema,
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

  final String appId;
  final String slug;
  final String name;
  final String? description;
  final String? version;
  final String? author;
  final String? note;
  final String? stableUri;
  final String? versionUri;
  final String? createdAt;
  final String? updatedAt;
  final bool isStable;
  final Map<String, dynamic> schema;

  factory AppDocumentModel.fromJson(Map<String, dynamic> json) {
    return AppDocumentModel(
      appId: json['appId'] as String? ?? '',
      slug: json['slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      version: json['version'] as String?,
      author: json['author'] as String?,
      note: json['note'] as String?,
      stableUri: json['stableUri'] as String?,
      versionUri: json['versionUri'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      isStable: json['isStable'] as bool? ?? false,
      schema: Map<String, dynamic>.from(
        json['schema'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }

  AppDocumentModel copyWith({
    String? appId,
    String? slug,
    String? name,
    String? description,
    String? version,
    String? author,
    String? note,
    String? stableUri,
    String? versionUri,
    String? createdAt,
    String? updatedAt,
    bool? isStable,
    Map<String, dynamic>? schema,
  }) {
    return AppDocumentModel(
      appId: appId ?? this.appId,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      author: author ?? this.author,
      note: note ?? this.note,
      stableUri: stableUri ?? this.stableUri,
      versionUri: versionUri ?? this.versionUri,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isStable: isStable ?? this.isStable,
      schema: schema ?? this.schema,
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

class SaveAppResultModel {
  SaveAppResultModel({
    required this.app,
    required this.stableUri,
    required this.versionUri,
  });

  final AppDocumentModel app;
  final String stableUri;
  final String versionUri;

  factory SaveAppResultModel.fromJson(Map<String, dynamic> json) {
    return SaveAppResultModel(
      app: AppDocumentModel.fromJson(
        Map<String, dynamic>.from(json['app'] as Map<String, dynamic>),
      ),
      stableUri: json['stableUri'] as String,
      versionUri: json['versionUri'] as String,
    );
  }
}

class CreateAppResultModel {
  CreateAppResultModel({
    required this.app,
    required this.stableUri,
    required this.versionUri,
    required this.warnings,
  });

  final AppDocumentModel app;
  final String stableUri;
  final String versionUri;
  final List<String> warnings;

  factory CreateAppResultModel.fromJson(Map<String, dynamic> json) {
    return CreateAppResultModel(
      app: AppDocumentModel.fromJson(
        Map<String, dynamic>.from(json['app'] as Map<String, dynamic>),
      ),
      stableUri: json['stableUri'] as String,
      versionUri: json['versionUri'] as String,
      warnings: (json['warnings'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class AndroidBuildResultModel {
  AndroidBuildResultModel({
    required this.success,
    required this.slug,
    required this.buildMode,
    required this.targetPlatform,
    required this.artifactPath,
    required this.logSummary,
    required this.startedAt,
    required this.completedAt,
    this.version,
    this.profileId,
  });

  final bool success;
  final String slug;
  final String? version;
  final String? profileId;
  final String buildMode;
  final String targetPlatform;
  final String artifactPath;
  final List<String> logSummary;
  final String startedAt;
  final String completedAt;

  factory AndroidBuildResultModel.fromJson(Map<String, dynamic> json) {
    return AndroidBuildResultModel(
      success: json['success'] as bool? ?? false,
      slug: json['slug'] as String? ?? '',
      version: json['version'] as String?,
      profileId: json['profileId'] as String?,
      buildMode: json['buildMode'] as String? ?? 'debug',
      targetPlatform: json['targetPlatform'] as String? ?? 'android-arm64',
      artifactPath: json['artifactPath'] as String? ?? '',
      logSummary: (json['logSummary'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      startedAt: json['startedAt'] as String? ?? '',
      completedAt: json['completedAt'] as String? ?? '',
    );
  }
}

class WebBuildResultModel {
  WebBuildResultModel({
    required this.success,
    required this.slug,
    required this.buildMode,
    required this.artifactPath,
    required this.logSummary,
    required this.startedAt,
    required this.completedAt,
    this.version,
    this.profileId,
  });

  final bool success;
  final String slug;
  final String? version;
  final String? profileId;
  final String buildMode;
  final String artifactPath;
  final List<String> logSummary;
  final String startedAt;
  final String completedAt;

  factory WebBuildResultModel.fromJson(Map<String, dynamic> json) {
    return WebBuildResultModel(
      success: json['success'] as bool? ?? false,
      slug: json['slug'] as String? ?? '',
      version: json['version'] as String?,
      profileId: json['profileId'] as String?,
      buildMode: json['buildMode'] as String? ?? 'release',
      artifactPath: json['artifactPath'] as String? ?? '',
      logSummary: (json['logSummary'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      startedAt: json['startedAt'] as String? ?? '',
      completedAt: json['completedAt'] as String? ?? '',
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

class AppValidationResultModel {
  AppValidationResultModel({
    required this.valid,
    required this.errors,
    required this.warnings,
    required this.normalizedSchema,
  });

  final bool valid;
  final List<ValidationIssueModel> errors;
  final List<ValidationIssueModel> warnings;
  final Map<String, dynamic> normalizedSchema;

  factory AppValidationResultModel.fromJson(Map<String, dynamic> json) {
    return AppValidationResultModel(
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
      normalizedSchema: Map<String, dynamic>.from(
        json['normalizedSchema'] as Map<String, dynamic>? ??
            <String, dynamic>{},
      ),
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

class PageUpdateResultModel {
  PageUpdateResultModel({
    required this.title,
    required this.definition,
    required this.summary,
    required this.warnings,
    required this.usedComponents,
    required this.assumptions,
    required this.appliedChanges,
  });

  final String title;
  final Map<String, dynamic> definition;
  final String summary;
  final List<String> warnings;
  final List<String> usedComponents;
  final List<String> assumptions;
  final List<String> appliedChanges;

  factory PageUpdateResultModel.fromJson(Map<String, dynamic> json) {
    return PageUpdateResultModel(
      title: json['title'] as String? ?? 'Untitled Page',
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
      appliedChanges: (json['appliedChanges'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class PageExplanationResultModel {
  PageExplanationResultModel({
    required this.summary,
    required this.pageType,
    required this.structure,
    required this.usedComponents,
    required this.actionSummary,
    required this.bindingSummary,
    required this.warnings,
  });

  final String summary;
  final String pageType;
  final List<String> structure;
  final List<String> usedComponents;
  final List<String> actionSummary;
  final List<String> bindingSummary;
  final List<String> warnings;

  factory PageExplanationResultModel.fromJson(Map<String, dynamic> json) {
    return PageExplanationResultModel(
      summary: json['summary'] as String? ?? '',
      pageType: json['pageType'] as String? ?? 'dashboard',
      structure: (json['structure'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      usedComponents: (json['usedComponents'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      actionSummary: (json['actionSummary'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      bindingSummary: (json['bindingSummary'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      warnings: (json['warnings'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class StudioSmokeEntryModel {
  StudioSmokeEntryModel({
    required this.title,
    required this.detail,
    required this.status,
    required this.timestamp,
  });

  final String title;
  final String detail;
  final String status;
  final String timestamp;
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
