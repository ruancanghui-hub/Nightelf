import 'dart:io';

import 'package:ai_workbench/features/skills/data/file_skill_repository.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../support/skill_fixture.dart';

void main() {
  late Directory vault;
  late FileSkillRepository repository;
  var nextId = 0;

  setUp(() async {
    vault = await Directory.systemTemp.createTemp('nightelf-skill-vault-');
    nextId = 0;
    repository = FileSkillRepository(
      vaultRoot: vault,
      writer: AtomicFileWriter(),
      idFactory: () => 'id-${++nextId}',
      clock: () => DateTime.utc(2026, 8, 9, 2, 30, 0),
    );
  });

  tearDown(() async {
    await vault.delete(recursive: true);
  });

  test('imports a valid SKILL directory without flattening it', () async {
    final source = await skillFixture({
      'SKILL.md': '# Apple Design',
      'references/motion.md': '# Motion',
      'assets/icon.png': [0, 1, 2, 3],
    });
    addTearDown(source.dispose);

    final imported = await repository.importDirectory(source.directory).last;
    expect(imported.skill!.entryRelativePath, 'skills/apple-design/SKILL.md');
    expect(
      File(
        '${vault.path}/skills/apple-design/references/motion.md',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '${vault.path}/skills/apple-design/assets/icon.png',
      ).readAsBytesSync(),
      [0, 1, 2, 3],
    );
  });

  test('resolves folder collisions and lists children lazily', () async {
    final first = await skillFixture({
      'SKILL.md': '# One',
    }, name: 'apple-design');
    addTearDown(first.dispose);
    await repository.importDirectory(first.directory).drain();

    final second = await skillFixture({
      'SKILL.md': '# Two',
      'b.txt': 'b',
      'a-dir/nested.md': 'n',
    }, name: 'apple-design');
    addTearDown(second.dispose);
    final imported = await repository.importDirectory(second.directory).last;
    expect(imported.skill!.relativeDirectory, 'skills/apple-design-2');

    final children = await repository.listChildren(
      imported.skill!.relativeDirectory,
    );
    expect(children.map((n) => n.name).toList(), [
      'a-dir',
      'b.txt',
      'SKILL.md',
    ]);
    expect(children.first.isDirectory, isTrue);
    expect(children.first.childrenLoaded, isFalse);

    final nested = await repository.listChildren(children.first.relativePath);
    expect(nested.single.name, 'nested.md');
  });

  test('rejects vault root and missing SKILL.md', () async {
    await expectLater(
      repository.importDirectory(vault).drain(),
      throwsA(isA<SkillImportException>()),
    );

    final bad = await skillFixture({'notes.md': 'x'}, name: 'broken');
    addTearDown(bad.dispose);
    await expectLater(
      repository.importDirectory(bad.directory).drain(),
      throwsA(isA<SkillImportException>()),
    );
  });

  test('requires confirmation for large files', () async {
    final source = await skillFixture({
      'SKILL.md': '# Large',
      'big.bin': List<int>.filled(8, 1),
    });
    addTearDown(source.dispose);

    final tinyThreshold = FileSkillRepository(
      vaultRoot: vault,
      writer: AtomicFileWriter(),
      idFactory: () => 'id-${++nextId}',
      largeFileThresholdBytes: 4,
    );

    await expectLater(
      tinyThreshold.importDirectory(source.directory).drain(),
      throwsA(isA<SkillImportException>()),
    );

    final imported = await tinyThreshold
        .importDirectory(
          source.directory,
          confirmLargeFile: (path, length) async => true,
        )
        .last;
    expect(imported.skill, isNotNull);
  });

  test('read write duplicate and trash', () async {
    final source = await skillFixture({'SKILL.md': '# Body\n'});
    addTearDown(source.dispose);
    final imported = await repository.importDirectory(source.directory).last;
    final relative = imported.skill!.relativeDirectory;

    await repository.writeTextFile(
      imported.skill!.entryRelativePath,
      '# Updated\n',
    );
    expect(
      await repository.readTextFile(imported.skill!.entryRelativePath),
      '# Updated\n',
    );

    final duplicated = await repository.duplicate(relative);
    expect(duplicated.relativeDirectory, 'skills/apple-design-副本');
    expect(
      File(p.join(vault.path, duplicated.entryRelativePath)).existsSync(),
      isTrue,
    );

    final trash = await repository.moveToTrash(relative);
    expect(Directory(p.join(vault.path, relative)).existsSync(), isFalse);
    expect(Directory(p.join(vault.path, trash)).existsSync(), isTrue);
    expect(
      trash,
      startsWith('.ai-workbench/local/trash/2026-08-09T02-30-00.000Z/skills/'),
    );
  });
}
