class LinkDocument {
  const LinkDocument({
    required this.id,
    required this.title,
    required this.uri,
    required this.description,
    required this.tags,
    required this.notes,
    required this.relativePath,
  });

  final String id;
  final String title;
  final Uri uri;
  final String description;
  final List<String> tags;
  final String notes;
  final String relativePath;

  LinkDocument copyWith({
    String? id,
    String? title,
    Uri? uri,
    String? description,
    List<String>? tags,
    String? notes,
    String? relativePath,
  }) {
    return LinkDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      uri: uri ?? this.uri,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      relativePath: relativePath ?? this.relativePath,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LinkDocument &&
        other.id == id &&
        other.title == title &&
        other.uri == uri &&
        other.description == description &&
        _listEquals(other.tags, tags) &&
        other.notes == notes &&
        other.relativePath == relativePath;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    uri,
    description,
    Object.hashAll(tags),
    notes,
    relativePath,
  );
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
