class SkillResource {
  const SkillResource({
    required this.id,
    required this.title,
    required this.relativeDirectory,
    required this.entryRelativePath,
  });

  final String id;
  final String title;
  final String relativeDirectory;
  final String entryRelativePath;

  SkillResource copyWith({
    String? id,
    String? title,
    String? relativeDirectory,
    String? entryRelativePath,
  }) {
    return SkillResource(
      id: id ?? this.id,
      title: title ?? this.title,
      relativeDirectory: relativeDirectory ?? this.relativeDirectory,
      entryRelativePath: entryRelativePath ?? this.entryRelativePath,
    );
  }
}
