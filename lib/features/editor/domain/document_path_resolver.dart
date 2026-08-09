import 'dart:io';

import 'package:ai_workbench/features/editor/domain/document_descriptor.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:path/path.dart' as p;

/// Resolves the editable file for a Vault-backed workbench resource.
DocumentDescriptor? documentDescriptorFor({
  required WorkbenchResource resource,
  required String vaultRootPath,
}) {
  final relativePath = resource.relativePath;
  if (relativePath == null || relativePath.isEmpty) {
    return null;
  }

  var absolutePath = p.join(vaultRootPath, relativePath);
  if (resource.type == ResourceType.skillFolder) {
    final skillFile = File(p.join(absolutePath, 'SKILL.md'));
    if (skillFile.existsSync()) {
      absolutePath = skillFile.path;
    } else {
      return null;
    }
  } else if (Directory(absolutePath).existsSync() &&
      !File(absolutePath).existsSync()) {
    return null;
  }

  return DocumentDescriptor(
    resourceId: resource.id,
    absolutePath: absolutePath,
    language: _languageFor(absolutePath, resource.type),
  );
}

DocumentLanguage _languageFor(String path, ResourceType type) {
  final extension = p.extension(path).toLowerCase();
  return switch (extension) {
    '.json' => DocumentLanguage.json,
    '.yml' || '.yaml' => DocumentLanguage.yaml,
    '.mmd' => DocumentLanguage.mermaid,
    '.md' || '.txt' || '.url' => DocumentLanguage.markdown,
    _ => switch (type) {
      ResourceType.mcpConfiguration => DocumentLanguage.json,
      ResourceType.workflowFile => DocumentLanguage.mermaid,
      _ => DocumentLanguage.plain,
    },
  };
}
