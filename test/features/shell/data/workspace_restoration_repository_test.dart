import 'dart:io';

import 'package:ai_workbench/features/metadata/data/json_metadata_repository.dart';
import 'package:ai_workbench/features/shell/data/workspace_restoration_repository.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('workspace restoration discards unknown resource ids', () async {
    final root = await Directory.systemTemp.createTemp('nightelf-restore-');
    addTearDown(() => root.delete(recursive: true));

    final repo = WorkspaceRestorationRepository(
      vaultRoot: root,
      writer: AtomicFileWriter(),
    );
    await repo.save(
      const WorkspaceRestorationState(
        openResourceIds: ['a', 'gone', 'b'],
        activeResourceId: 'gone',
        sidebarWidth: 260,
        inspectorVisible: false,
      ),
    );

    final loaded = await repo.load(knownResourceIds: {'a', 'b'});
    expect(loaded.openResourceIds, ['a', 'b']);
    expect(loaded.activeResourceId, 'a');
    expect(loaded.sidebarWidth, 260);
    expect(loaded.inspectorVisible, isFalse);
    expect(
      File(
        p.join(root.path, '.ai-workbench', 'local', 'workspace.json'),
      ).existsSync(),
      isTrue,
    );
  });

  test('favorites and workspace files stay vault-local', () async {
    final root = await Directory.systemTemp.createTemp('nightelf-local-');
    addTearDown(() => root.delete(recursive: true));
    await JsonMetadataRepository(vaultRoot: root).recordRecent('x');
    await WorkspaceRestorationRepository(
      vaultRoot: root,
    ).save(const WorkspaceRestorationState(openResourceIds: ['x']));
    expect(
      File(
        p.join(root.path, '.ai-workbench', 'local', 'recent.json'),
      ).existsSync(),
      isTrue,
    );
  });
}
