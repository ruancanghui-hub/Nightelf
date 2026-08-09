import 'dart:io';

import 'package:ai_workbench/features/import/application/import_controller.dart';
import 'package:ai_workbench/features/import/data/vault_import_repository.dart';
import 'package:ai_workbench/features/vault/data/file_vault_repository.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../support/import_source_fixture.dart';

void main() {
  test('prepare classifies paths and confirm refreshes after commit', () async {
    final sourceFixture = await ImportSourceFixture.create();
    addTearDown(sourceFixture.dispose);
    final vaultRoot = await Directory.systemTemp.createTemp(
      'nightelf-import-ctrl-',
    );
    addTearDown(() => vaultRoot.delete(recursive: true));
    final vault = await FileVaultRepository().create(vaultRoot, '控制器');
    final prompt = await sourceFixture.file('release.md', '# release');
    final unknown = await sourceFixture.file('blob.bin');

    final refreshed = <Set<String>>[];
    final controller = ImportController(
      repository: VaultImportRepository(),
      onImported: (paths) async => refreshed.add(paths),
    );
    addTearDown(controller.dispose);

    await controller.prepare([prompt.path, unknown.path]);
    expect(controller.plan.items, hasLength(2));
    expect(controller.canConfirm, isFalse);

    controller.setType(1, ResourceType.prompt);
    expect(controller.canConfirm, isTrue);

    final results = await controller.confirm(vault);
    expect(results.every((result) => result.succeeded), isTrue);
    expect(refreshed, hasLength(1));
    expect(
      refreshed.single,
      containsAll([
        p.join('prompts', 'release.md'),
        p.join('prompts', 'blob.bin'),
      ]),
    );
    expect(controller.plan.items, isEmpty);
  });

  test('cancel clears the plan without importing', () async {
    final sourceFixture = await ImportSourceFixture.create();
    addTearDown(sourceFixture.dispose);
    final prompt = await sourceFixture.file('a.md');
    final controller = ImportController(repository: VaultImportRepository());
    addTearDown(controller.dispose);

    await controller.prepare([prompt.path]);
    controller.cancel();

    expect(controller.plan.items, isEmpty);
    expect(controller.statusMessage, '已取消导入');
  });
}
