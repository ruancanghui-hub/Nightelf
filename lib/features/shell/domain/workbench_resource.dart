/// The resource categories displayed by the visual workbench shell.
enum ResourceType {
  aiPrompt,
  skillFolder,
  mcpConfiguration,
  websiteLink,
  workflowFile,
}

/// A workbench list/detail record, optionally backed by a Vault relative path.
class WorkbenchResource {
  const WorkbenchResource({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.isFavorite,
    this.relativePath,
    this.modifiedAt,
  });

  final String id;
  final ResourceType type;
  final String title;
  final String subtitle;
  final bool isFavorite;

  /// Vault-relative path when this row comes from a real scan; null for mocks.
  final String? relativePath;

  /// File modification time from the Vault scan when available.
  final DateTime? modifiedAt;

  WorkbenchResource copyWith({
    String? id,
    ResourceType? type,
    String? title,
    String? subtitle,
    bool? isFavorite,
    String? relativePath,
    DateTime? modifiedAt,
  }) {
    return WorkbenchResource(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      isFavorite: isFavorite ?? this.isFavorite,
      relativePath: relativePath ?? this.relativePath,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WorkbenchResource &&
        other.id == id &&
        other.type == type &&
        other.title == title &&
        other.subtitle == subtitle &&
        other.isFavorite == isFavorite &&
        other.relativePath == relativePath &&
        other.modifiedAt == modifiedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    title,
    subtitle,
    isFavorite,
    relativePath,
    modifiedAt,
  );
}
