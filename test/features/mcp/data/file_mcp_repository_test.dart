import 'dart:io';

import 'package:ai_workbench/features/mcp/data/file_mcp_repository.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late FileMcpRepository repository;
  var nextId = 0;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('nightelf-mcp-');
    nextId = 0;
    repository = FileMcpRepository(
      vaultRoot: root,
      writer: AtomicFileWriter(),
      idFactory: () => 'id-${++nextId}',
      clock: () => DateTime.utc(2026, 8, 9, 2, 30, 0),
    );
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  test(
    'create reopen duplicate keep invalid json and metadata outside file',
    () async {
      final created = await repository.create(
        title: '文件系统',
        description: '本地文件',
        tags: const ['mcp'],
        jsonText: '{\n  "mcpServers": {}\n}\n',
      );
      expect(created.relativePath, 'mcp/文件系统.json');
      expect(created.id, 'id-1');

      final invalid = await repository.save(
        created.copyWith(jsonText: '{\n  "mcpServers": {\n'),
      );
      expect(
        await File(p.join(root.path, invalid.relativePath)).readAsString(),
        '{\n  "mcpServers": {\n',
      );

      final reopened = await repository.read(created.relativePath);
      expect(reopened.title, '文件系统');
      expect(reopened.description, '本地文件');
      expect(reopened.tags, ['mcp']);
      expect(reopened.jsonText, '{\n  "mcpServers": {\n');
      expect(
        File(
          p.join(root.path, '.ai-workbench/resources/mcp-metadata.json'),
        ).existsSync(),
        isTrue,
      );
      expect(
        File(p.join(root.path, created.relativePath)).readAsStringSync(),
        isNot(contains('"title"')),
      );

      final second = await repository.create(title: '文件系统', jsonText: '{}\n');
      expect(second.relativePath, 'mcp/文件系统-2.json');

      final duplicated = await repository.duplicate(created.relativePath);
      expect(duplicated.id, 'id-3');
      expect(duplicated.title, '文件系统 副本');
      expect(duplicated.relativePath, 'mcp/文件系统-副本.json');
    },
  );

  test('moveToTrash keeps recoverable copy', () async {
    final created = await repository.create(title: '临时', jsonText: '{}\n');
    final trash = await repository.moveToTrash(created.relativePath);
    expect(File(p.join(root.path, created.relativePath)).existsSync(), isFalse);
    expect(File(p.join(root.path, trash)).existsSync(), isTrue);
    expect(
      trash,
      startsWith('.ai-workbench/local/trash/2026-08-09T02-30-00.000Z/mcp/'),
    );
  });
}
