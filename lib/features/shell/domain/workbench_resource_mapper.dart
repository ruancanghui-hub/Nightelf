import 'package:ai_workbench/features/shell/domain/workbench_resource.dart'
    as shell;
import 'package:ai_workbench/features/vault/domain/resource_record.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart' as vault;

shell.WorkbenchResource workbenchResourceFromRecord(ResourceRecord record) {
  return shell.WorkbenchResource(
    id: record.id,
    type: _mapType(record.type),
    title: record.title,
    subtitle: record.description.isEmpty
        ? record.relativePath
        : record.description,
    isFavorite: false,
    relativePath: record.relativePath,
  );
}

shell.ResourceType _mapType(vault.ResourceType type) => switch (type) {
  vault.ResourceType.prompt => shell.ResourceType.aiPrompt,
  vault.ResourceType.skill => shell.ResourceType.skillFolder,
  vault.ResourceType.mcp => shell.ResourceType.mcpConfiguration,
  vault.ResourceType.link => shell.ResourceType.websiteLink,
  vault.ResourceType.workflow => shell.ResourceType.workflowFile,
};
