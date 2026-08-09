import 'dart:io';

import 'package:ai_workbench/features/links/data/file_link_repository.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late FileLinkRepository repository;
  var nextId = 0;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('nightelf-link-');
    nextId = 0;
    repository = FileLinkRepository(
      vaultRoot: root,
      writer: AtomicFileWriter(),
      idFactory: () => 'id-${++nextId}',
      clock: () => DateTime.utc(2026, 8, 9, 2, 30, 0),
    );
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('create reopen duplicate and trash', () async {
    final created = await repository.create(
      title: 'MDN',
      uri: Uri.parse('https://developer.mozilla.org/'),
      notes: 'docs\n',
    );
    expect(created.relativePath, 'links/mdn.md');
    expect(created.id, 'id-1');

    final reopened = await repository.read(created.relativePath);
    expect(reopened.uri.toString(), 'https://developer.mozilla.org/');
    expect(reopened.notes, 'docs\n');

    final second = await repository.create(
      title: 'MDN',
      uri: Uri.parse('https://example.com'),
    );
    expect(second.relativePath, 'links/mdn-2.md');

    final duplicated = await repository.duplicate(created.relativePath);
    expect(duplicated.id, 'id-3');
    expect(duplicated.title, 'MDN 副本');

    final trash = await repository.moveToTrash(created.relativePath);
    expect(File(p.join(root.path, created.relativePath)).existsSync(), isFalse);
    expect(File(p.join(root.path, trash)).existsSync(), isTrue);
  });
}
