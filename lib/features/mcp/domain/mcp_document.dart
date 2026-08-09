class McpDocument {
  const McpDocument({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.jsonText,
    required this.relativePath,
  });

  final String id;
  final String title;
  final String description;
  final List<String> tags;
  final String jsonText;
  final String relativePath;

  McpDocument copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? tags,
    String? jsonText,
    String? relativePath,
  }) {
    return McpDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      jsonText: jsonText ?? this.jsonText,
      relativePath: relativePath ?? this.relativePath,
    );
  }
}
