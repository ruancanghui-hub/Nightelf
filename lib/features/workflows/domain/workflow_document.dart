class WorkflowDocument {
  const WorkflowDocument({
    required this.id,
    required this.title,
    required this.source,
    required this.extension,
    required this.relativePath,
    this.description = '',
    this.tags = const [],
  });

  final String id;
  final String title;
  final String source;
  final String extension;
  final String relativePath;
  final String description;
  final List<String> tags;

  bool get supportsCanvas {
    final ext = extension.toLowerCase();
    return ext == '.mmd' || ext == '.md';
  }

  WorkflowDocument copyWith({
    String? id,
    String? title,
    String? source,
    String? extension,
    String? relativePath,
    String? description,
    List<String>? tags,
  }) {
    return WorkflowDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      source: source ?? this.source,
      extension: extension ?? this.extension,
      relativePath: relativePath ?? this.relativePath,
      description: description ?? this.description,
      tags: tags ?? this.tags,
    );
  }
}
