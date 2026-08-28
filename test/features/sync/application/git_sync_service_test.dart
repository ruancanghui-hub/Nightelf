import 'dart:io';

import 'package:ai_workbench/features/sync/application/git_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

Future<void> _git(
  String cwd,
  List<String> args, {
  bool allowFailure = false,
}) async {
  final result = await Process.run(
    'git',
    args,
    workingDirectory: cwd,
    environment: {
      ...Platform.environment,
      'GIT_AUTHOR_NAME': 'Nightelf Test',
      'GIT_AUTHOR_EMAIL': 'test@example.com',
      'GIT_COMMITTER_NAME': 'Nightelf Test',
      'GIT_COMMITTER_EMAIL': 'test@example.com',
    },
  );
  if (!allowFailure && result.exitCode != 0) {
    fail('git ${args.join(' ')} failed: ${result.stderr}\n${result.stdout}');
  }
}

Future<void> _write(String path, String contents) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(contents);
}

void main() {
  test('clears stuck rebase-merge and completes sync', () async {
    final root = await Directory.systemTemp.createTemp('nightelf-git-sync-');
    addTearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    final remote = Directory(p.join(root.path, 'remote.git'));
    final seed = Directory(p.join(root.path, 'seed'));
    final local = Directory(p.join(root.path, 'local'));
    await remote.create(recursive: true);

    await _git(root.path, ['init', '--bare', '-b', 'main', remote.path]);
    await _git(root.path, ['clone', remote.path, seed.path]);
    await _write(p.join(seed.path, 'README.md'), 'remote\n');
    await _git(seed.path, ['add', '-A']);
    await _git(seed.path, ['commit', '-m', 'seed']);
    await _git(seed.path, ['push', '-u', 'origin', 'main']);

    await _git(root.path, ['clone', remote.path, local.path]);
    await Directory(p.join(local.path, '.git', 'rebase-merge')).create();
    await _write(
      p.join(local.path, '.git', 'rebase-merge', 'git-rebase-todo'),
      '',
    );

    await _write(p.join(local.path, 'local.txt'), 'local\n');
    await _git(local.path, ['add', '-A']);
    await _git(local.path, ['commit', '-m', 'local']);

    await _write(p.join(seed.path, 'remote.txt'), 'more\n');
    await _git(seed.path, ['add', '-A']);
    await _git(seed.path, ['commit', '-m', 'remote-2']);
    await _git(seed.path, ['push']);

    final result = await GitSyncService().syncVault(
      vaultRootPath: local.path,
      remoteUrl: remote.path,
    );

    expect(result.status, GitSyncStatus.success, reason: result.message);
    expect(
      await Directory(p.join(local.path, '.git', 'rebase-merge')).exists(),
      isFalse,
    );
    expect(File(p.join(local.path, 'remote.txt')).existsSync(), isTrue);
    expect(File(p.join(local.path, 'local.txt')).existsSync(), isTrue);
  });
}
