enum DocumentLanguage { markdown, json, yaml, plain, mermaid }

class DocumentDescriptor {
  const DocumentDescriptor({
    required this.resourceId,
    required this.absolutePath,
    required this.language,
    this.readOnly = false,
  });

  final String resourceId;
  final String absolutePath;
  final DocumentLanguage language;
  final bool readOnly;
}
