import 'dart:io';

import 'package:ai_workbench/features/workflows/data/file_workflow_repository.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late FileWorkflowRepository repository;
  var nextId = 0;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('nightelf-workflow-');
    nextId = 0;
    repository = FileWorkflowRepository(
      vaultRoot: root,
      writer: AtomicFileWriter(),
      idFactory: () => 'wf-${++nextId}',
      clock: () => DateTime.utc(2026, 8, 9, 3, 0, 0),
    );
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('create reopen duplicate import and trash', () async {
    final created = await repository.create(title: '发布流程');
    expect(created.relativePath, 'workflows/发布流程.mmd');
    expect(created.id, 'wf-1');
    expect(created.source, contains('flowchart TD'));

    final reopened = await repository.read(created.relativePath);
    expect(reopened.title, '发布流程');
    expect(reopened.source, created.source);

    final duplicated = await repository.duplicate(created.relativePath);
    expect(duplicated.id, 'wf-2');
    expect(duplicated.title, '发布流程 副本');

    final importSource = File(p.join(root.path, 'external.mmd'))
      ..writeAsStringSync('flowchart LR\na --> b\n');
    final imported = await repository.importFile(
      absolutePath: importSource.path,
    );
    expect(imported.extension, '.mmd');
    expect(imported.source.trim(), 'flowchart LR\na --> b');

    final trash = await repository.moveToTrash(created.relativePath);
    expect(File(p.join(root.path, created.relativePath)).existsSync(), isFalse);
    expect(File(p.join(root.path, trash)).existsSync(), isTrue);
  });
}
