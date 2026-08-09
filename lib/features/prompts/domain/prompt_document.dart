class PromptDocument {
  const PromptDocument({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.body,
    required this.relativePath,
  });

  final String id;
  final String title;
  final String description;
  final List<String> tags;
  final String body;
  final String relativePath;

  PromptDocument copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? tags,
    String? body,
    String? relativePath,
  }) {
    return PromptDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      body: body ?? this.body,
      relativePath: relativePath ?? this.relativePath,
    );
  }
}
