import 'package:ai_workbench/shared/domain/resource_type.dart';

/// Stable paths used for every Vault's marker and managed metadata.
class VaultPaths {
  VaultPaths._();

  static const marker = '.ai-vault.json';
  static const metadataRoot = '.ai-workbench';
  static const localRoot = '.ai-workbench/local';
  static const resourceMetadata = '.ai-workbench/resources';
  static const workflowLayouts = '.ai-workbench/workflow-layouts';

  static String directoryFor(ResourceType type) => switch (type) {
    ResourceType.prompt => 'prompts',
    ResourceType.skill => 'skills',
    ResourceType.mcp => 'mcp',
    ResourceType.link => 'links',
    ResourceType.workflow => 'workflows',
  };
}
