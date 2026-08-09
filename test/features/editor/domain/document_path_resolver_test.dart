import 'dart:io';

import 'package:ai_workbench/features/editor/domain/document_descriptor.dart';
import 'package:ai_workbench/features/editor/domain/document_path_resolver.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('resolves prompt files and skill SKILL.md paths', () async {
    final root = await Directory.systemTemp.createTemp('nightelf-doc-path-');
    addTearDown(() => root.delete(recursive: true));
    await Directory(p.join(root.path, 'prompts')).create(recursive: true);
    await File(p.join(root.path, 'prompts', 'a.md')).writeAsString('hi');
    await Directory(
      p.join(root.path, 'skills', 'demo'),
    ).create(recursive: true);
    await File(
      p.join(root.path, 'skills', 'demo', 'SKILL.md'),
    ).writeAsString('# demo');

    final prompt = documentDescriptorFor(
      resource: const WorkbenchResource(
        id: 'p1',
        type: ResourceType.aiPrompt,
        title: 'a',
        subtitle: '',
        isFavorite: false,
        relativePath: 'prompts/a.md',
      ),
      vaultRootPath: root.path,
    );
    expect(prompt?.absolutePath, p.join(root.path, 'prompts', 'a.md'));
    expect(prompt?.language, DocumentLanguage.markdown);

    final skill = documentDescriptorFor(
      resource: const WorkbenchResource(
        id: 's1',
        type: ResourceType.skillFolder,
        title: 'demo',
        subtitle: '',
        isFavorite: false,
        relativePath: 'skills/demo',
      ),
      vaultRootPath: root.path,
    );
    expect(
      skill?.absolutePath,
      p.join(root.path, 'skills', 'demo', 'SKILL.md'),
    );
  });
}
