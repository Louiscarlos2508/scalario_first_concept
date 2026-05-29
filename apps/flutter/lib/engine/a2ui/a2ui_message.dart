import 'a2ui_component.dart';

/// Types de messages A2UI v0.9.
enum A2UIMessageType {
  createSurface,
  updateComponents,
  updateDataModel,
  deleteSurface,
  error;

  static A2UIMessageType? fromString(String key) {
    switch (key) {
      case 'createSurface':
        return A2UIMessageType.createSurface;
      case 'updateComponents':
        return A2UIMessageType.updateComponents;
      case 'updateDataModel':
        return A2UIMessageType.updateDataModel;
      case 'deleteSurface':
        return A2UIMessageType.deleteSurface;
      case 'error':
        return A2UIMessageType.error;
      default:
        return null;
    }
  }
}

/// Message A2UI v0.9 reçu du serveur.
///
/// Contient exactement un body (`createSurface`, `updateComponents`, …).
class A2UIMessage {
  const A2UIMessage({
    required this.type,
    required this.version,
    this.createSurface,
    this.updateComponents,
    this.updateDataModel,
    this.deleteSurface,
    this.error,
  });

  factory A2UIMessage.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as String? ?? 'v0.9';
    final bodyKey = json.keys.firstWhere(
      (k) => k != 'version' && A2UIMessageType.fromString(k) != null,
      orElse: () => '',
    );
    final type = A2UIMessageType.fromString(bodyKey);

    if (type == null) {
      throw ArgumentError('Unknown A2UI message type: $bodyKey');
    }

    final body = json[bodyKey] as Map<String, dynamic>? ?? {};

    return A2UIMessage(
      type: type,
      version: version,
      createSurface: type == A2UIMessageType.createSurface
          ? CreateSurface.fromJson(body)
          : null,
      updateComponents: type == A2UIMessageType.updateComponents
          ? UpdateComponents.fromJson(body)
          : null,
      updateDataModel: type == A2UIMessageType.updateDataModel
          ? UpdateDataModel.fromJson(body)
          : null,
      deleteSurface: type == A2UIMessageType.deleteSurface
          ? DeleteSurface.fromJson(body)
          : null,
      error: type == A2UIMessageType.error
          ? A2UIError.fromJson(body)
          : null,
    );
  }

  final A2UIMessageType type;
  final String version;
  final CreateSurface? createSurface;
  final UpdateComponents? updateComponents;
  final UpdateDataModel? updateDataModel;
  final DeleteSurface? deleteSurface;
  final A2UIError? error;
}

/// createSurface — crée une nouvelle surface de rendu.
class CreateSurface {
  const CreateSurface({
    required this.surfaceId,
    required this.catalogId,
    this.theme,
  });

  factory CreateSurface.fromJson(Map<String, dynamic> json) {
    return CreateSurface(
      surfaceId: json['surfaceId'] as String,
      catalogId: json['catalogId'] as String,
      theme: json['theme'] != null
          ? Map<String, dynamic>.from(json['theme'] as Map)
          : null,
    );
  }

  final String surfaceId;
  final String catalogId;
  final Map<String, dynamic>? theme;
}

/// updateComponents — liste plate de composants.
class UpdateComponents {
  const UpdateComponents({
    required this.surfaceId,
    this.components = const [],
  });

  factory UpdateComponents.fromJson(Map<String, dynamic> json) {
    final raw = json['components'] as List<dynamic>? ?? [];
    return UpdateComponents(
      surfaceId: json['surfaceId'] as String,
      components: raw
          .map((e) => A2UIComponent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String surfaceId;
  final List<A2UIComponent> components;
}

/// updateDataModel — met à jour le data model.
class UpdateDataModel {
  const UpdateDataModel({
    required this.surfaceId,
    this.path,
    this.value,
  });

  factory UpdateDataModel.fromJson(Map<String, dynamic> json) {
    return UpdateDataModel(
      surfaceId: json['surfaceId'] as String,
      path: json['path'] as String?,
      value: json['value'],
    );
  }

  final String surfaceId;
  final String? path;
  final dynamic value;
}

/// deleteSurface — supprime une surface.
class DeleteSurface {
  const DeleteSurface({required this.surfaceId});

  factory DeleteSurface.fromJson(Map<String, dynamic> json) {
    return DeleteSurface(
      surfaceId: json['surfaceId'] as String,
    );
  }

  final String surfaceId;
}

/// Erreur A2UI.
class A2UIError {
  const A2UIError({
    this.code,
    this.message,
    this.surfaceId,
  });

  factory A2UIError.fromJson(Map<String, dynamic> json) {
    return A2UIError(
      code: json['code'] as String?,
      message: json['message'] as String?,
      surfaceId: json['surfaceId'] as String?,
    );
  }

  final String? code;
  final String? message;
  final String? surfaceId;
}
