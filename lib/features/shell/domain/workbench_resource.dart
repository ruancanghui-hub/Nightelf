/// The resource categories displayed by the visual workbench shell.
enum ResourceType {
  aiPrompt,
  skillFolder,
  mcpConfiguration,
  websiteLink,
  workflowFile,
}

/// A deterministic visual stand-in for a future Vault-backed resource.
class WorkbenchResource {
  const WorkbenchResource({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.isFavorite,
  });

  final String id;
  final ResourceType type;
  final String title;
  final String subtitle;
  final bool isFavorite;
}
