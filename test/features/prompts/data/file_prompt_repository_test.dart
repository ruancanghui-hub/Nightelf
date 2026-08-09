import 'dart:io';

import 'package:ai_workbench/features/prompts/data/file_prompt_repository.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late FilePromptRepository repository;
  var nextId = 0;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('nightelf-prompt-');
    nextId = 0;
    repository = FilePromptRepository(
      vaultRoot: root,
      writer: AtomicFileWriter(),
      idFactory: () => 'id-${++nextId}',
      clock: () => DateTime.utc(2026, 8, 9, 2, 30, 0),
    );
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('create reopen duplicate and collision naming', () async {
    final first = await repository.create(
      title: '代码审查助手',
      description: '检查安全与性能',
      tags: const ['代码'],
      body: '# 角色\n你是审查员。\n',
    );
    expect(first.relativePath, 'prompts/代码审查助手.md');
    expect(first.id, 'id-1');

    final second = await repository.create(title: '代码审查助手', body: 'x\n');
    expect(second.relativePath, 'prompts/代码审查助手-2.md');

    final reopened = await repository.read(first.relativePath);
    expect(reopened.body, '# 角色\n你是审查员。\n');

    final duplicate = await repository.duplicate(first.relativePath);
    expect(duplicate.id, 'id-3');
    expect(duplicate.title, '代码审查助手 副本');
    expect(duplicate.relativePath, 'prompts/代码审查助手-副本.md');
    expect(duplicate.body, first.body);
  });

  test('moveToTrash keeps recoverable vault-local copy', () async {
    final created = await repository.create(title: '临时', body: 'body\n');
    final trashPath = await repository.moveToTrash(created.relativePath);
    expect(File(p.join(root.path, created.relativePath)).existsSync(), isFalse);
    expect(File(p.join(root.path, trashPath)).existsSync(), isTrue);
    expect(
      trashPath,
      startsWith('.ai-workbench/local/trash/2026-08-09T02-30-00.000Z/prompts/'),
    );
  });

  test('rename updates title and filename', () async {
    final created = await repository.create(title: '未命名提示词', body: 'body\n');
    final renamed = await repository.rename(
      created.relativePath,
      title: '代码审查',
      body: 'body\n',
    );
    expect(renamed.title, '代码审查');
    expect(renamed.relativePath, 'prompts/代码审查.md');
    expect(File(p.join(root.path, created.relativePath)).existsSync(), isFalse);
    expect(File(p.join(root.path, renamed.relativePath)).existsSync(), isTrue);
  });

  test('slugify keeps chinese and lowercases ascii', () {
    expect(slugifyPromptTitle('Hello 世界!!'), 'hello-世界');
    expect(slugifyPromptTitle('   '), 'prompt');
  });
}
