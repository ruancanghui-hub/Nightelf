import 'dart:io';

import 'package:ai_workbench/features/launchers/data/file_launcher_repository.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late FileLauncherRepository repository;
  var nextId = 0;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('nightelf-launcher-');
    nextId = 0;
    repository = FileLauncherRepository(
      vaultRoot: root,
      writer: AtomicFileWriter(),
      idFactory: () => 'id-${++nextId}',
      clock: () => DateTime.utc(2026, 8, 9, 2, 30, 0),
    );
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('create reopen rename and trash', () async {
    final created = await repository.create(
      title: 'Nightelf',
      scriptPath: '/tmp/launch_macos.sh',
    );
    expect(created.relativePath, 'launchers/nightelf.md');
    expect(created.id, 'id-1');

    final reopened = await repository.read(created.relativePath);
    expect(reopened.scriptPath, '/tmp/launch_macos.sh');
    expect(reopened.title, 'Nightelf');

    final second = await repository.create(
      title: 'Nightelf',
      scriptPath: '/tmp/other.command',
    );
    expect(second.relativePath, 'launchers/nightelf-2.md');

    final renamed = await repository.rename(
      created.relativePath,
      title: '暗夜精灵',
    );
    expect(renamed.title, '暗夜精灵');
    expect(renamed.relativePath, 'launchers/暗夜精灵.md');
    expect(File(p.join(root.path, created.relativePath)).existsSync(), isFalse);

    final trash = await repository.moveToTrash(renamed.relativePath);
    expect(File(p.join(root.path, renamed.relativePath)).existsSync(), isFalse);
    expect(File(p.join(root.path, trash)).existsSync(), isTrue);
  });
}
