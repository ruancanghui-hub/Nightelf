class LauncherDocument {
  const LauncherDocument({
    required this.id,
    required this.title,
    required this.scriptPath,
    required this.relativePath,
  });

  final String id;
  final String title;
  final String scriptPath;
  final String relativePath;

  LauncherDocument copyWith({
    String? id,
    String? title,
    String? scriptPath,
    String? relativePath,
  }) {
    return LauncherDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      scriptPath: scriptPath ?? this.scriptPath,
      relativePath: relativePath ?? this.relativePath,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LauncherDocument &&
        other.id == id &&
        other.title == title &&
        other.scriptPath == scriptPath &&
        other.relativePath == relativePath;
  }

  @override
  int get hashCode => Object.hash(id, title, scriptPath, relativePath);
}
