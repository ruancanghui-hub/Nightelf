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
  });

  final String id;
  final ResourceType type;
  final String title;
  final String subtitle;
  final bool isFavorite;

  /// Vault-relative path when this row comes from a real scan; null for mocks.
  final String? relativePath;
}
