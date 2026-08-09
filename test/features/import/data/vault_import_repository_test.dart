import 'dart:io';

import 'package:ai_workbench/features/import/data/vault_import_repository.dart';
import 'package:ai_workbench/features/import/domain/import_candidate.dart';
import 'package:ai_workbench/features/import/domain/import_plan.dart';
import 'package:ai_workbench/features/vault/data/file_vault_repository.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../support/import_source_fixture.dart';

ImportPlanItem promptItem(
  String sourcePath, {
  String basename = 'original.md',
}) {
  return ImportPlanItem(
    candidate: ImportCandidate(
      sourcePath: sourcePath,
      isDirectory: false,
      suggestedType: ResourceType.prompt,
      reason: '按扩展名识别为提示词',
    ),
    selectedType: ResourceType.prompt,
    title: p.basenameWithoutExtension(basename),
    targetBasename: basename,
    isSelected: true,
  );
}

void main() {
  test('copies a prompt and leaves the source unchanged', () async {
    final sourceFixture = await ImportSourceFixture.create();
    addTearDown(sourceFixture.dispose);
    final vaultRoot = await Directory.systemTemp.createTemp(
      'nightelf-import-vault-',
    );
    addTearDown(() => vaultRoot.delete(recursive: true));

    final vault = await FileVaultRepository().create(vaultRoot, '导入测试');
    final source = await sourceFixture.file('original.md', '# keep me');
    final repository = VaultImportRepository();

    final result = await repository.importItem(vault, promptItem(source.path));

    expect(result.succeeded, isTrue);
    expect(await File(source.path).readAsString(), '# keep me');
    expect(await File(result.resourcePath!).readAsString(), '# keep me');
    expect(
      result.resourcePath,
      p.join(vaultRoot.path, 'prompts', 'original.md'),
    );
  });

  test('failed copy leaves no temporary or final target', () async {
    final sourceFixture = await ImportSourceFixture.create();
    addTearDown(sourceFixture.dispose);
    final vaultRoot = await Directory.systemTemp.createTemp(
      'nightelf-import-fail-',
    );
    addTearDown(() => vaultRoot.delete(recursive: true));
    final vault = await FileVaultRepository().create(vaultRoot, '导入失败');
    final source = await sourceFixture.file('original.md', '# keep me');
    final targetDirectory = Directory(p.join(vaultRoot.path, 'prompts'));

    final repository = VaultImportRepository(
      copyHandler:
          ({
            required sourcePath,
            required destinationPath,
            required isDirectory,
          }) async {
            throw StateError('boom');
          },
    );

    final result = await repository.importItem(vault, promptItem(source.path));

    expect(result.succeeded, isFalse);
    final leftovers = await targetDirectory
        .list()
        .where((entity) => entity.path.contains('.importing-'))
        .toList();
    expect(leftovers, isEmpty);
    expect(
      File(p.join(targetDirectory.path, 'original.md')).existsSync(),
      isFalse,
    );
  });

  test(
    'allocates numbered names on collision and preserves skill trees',
    () async {
      final sourceFixture = await ImportSourceFixture.create();
      addTearDown(sourceFixture.dispose);
      final vaultRoot = await Directory.systemTemp.createTemp(
        'nightelf-import-col-',
      );
      addTearDown(() => vaultRoot.delete(recursive: true));
      final vault = await FileVaultRepository().create(vaultRoot, '冲突');
      await File(
        p.join(vaultRoot.path, 'prompts', 'original.md'),
      ).writeAsString('old');

      final repository = VaultImportRepository();
      final source = await sourceFixture.file('original.md', 'new');
      final promptResult = await repository.importItem(
        vault,
        promptItem(source.path),
      );
      expect(promptResult.succeeded, isTrue);
      expect(p.basename(promptResult.resourcePath!), 'original 2.md');

      final skill = await sourceFixture.skillDirectory('apple-design');
      final skillResult = await repository.importItem(
        vault,
        ImportPlanItem(
          candidate: ImportCandidate(
            sourcePath: skill.path,
            isDirectory: true,
            suggestedType: ResourceType.skill,
            reason: '检测到 SKILL.md',
          ),
          selectedType: ResourceType.skill,
          title: 'apple-design',
          targetBasename: 'apple-design',
          isSelected: true,
        ),
      );
      expect(skillResult.succeeded, isTrue);
      expect(
        File(p.join(skillResult.resourcePath!, 'SKILL.md')).existsSync(),
        isTrue,
      );
      expect(
        File(p.join(skillResult.resourcePath!, 'notes.txt')).existsSync(),
        isTrue,
      );
    },
  );

  test('rejects unknown type until selected', () async {
    final sourceFixture = await ImportSourceFixture.create();
    addTearDown(sourceFixture.dispose);
    final vaultRoot = await Directory.systemTemp.createTemp(
      'nightelf-import-unk-',
    );
    addTearDown(() => vaultRoot.delete(recursive: true));
    final vault = await FileVaultRepository().create(vaultRoot, '未知');
    final source = await sourceFixture.file('diagram.bin');
    final repository = VaultImportRepository();

    final result = await repository.importItem(
      vault,
      ImportPlanItem(
        candidate: ImportCandidate(
          sourcePath: source.path,
          isDirectory: false,
          suggestedType: null,
          reason: '无法自动识别类型',
        ),
        selectedType: null,
        title: 'diagram',
        targetBasename: 'diagram.bin',
        isSelected: true,
      ),
    );

    expect(result.succeeded, isFalse);
    expect(result.failureReason, contains('请先选择资源类型'));
  });
}
