import 'dart:io';

import 'package:ai_workbench/features/vault/application/vault_controller.dart';
import 'package:ai_workbench/features/vault/application/vault_state.dart';
import 'package:ai_workbench/features/vault/data/vault_repository.dart';
import 'package:ai_workbench/features/vault/domain/vault_handle.dart';
import 'package:ai_workbench/features/vault/domain/vault_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/resource_factories.dart';
import 'vault_controller_fakes.dart';

void main() {
  late Directory root;
  late VaultHandle handle;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('nightelf-controller-');
    handle = VaultHandle(
      root,
      const VaultManifest(version: 1, id: 'vault-1', name: '测试库'),
    );
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test('restores a valid last Vault and rebuilds the index', () async {
    final record = promptRecord(id: 'p1');
    final repository = FakeVaultRepository.opening(handle);
    final scanner = FakeResourceScanner([record]);
    final index = RecordingSearchIndex();
    final settings = MemoryAppSettings(lastVaultPath: handle.root.path);
    final controller = VaultController(
      repository: repository,
      scan: scanner.scan,
      index: index,
      settings: settings,
      watch: (_) => const Stream.empty(),
    );
    addTearDown(controller.dispose);

    await controller.restoreLastVault();

    expect(controller.state, isA<VaultOpen>());
    final open = controller.state as VaultOpen;
    expect(open.handle, handle);
    expect(open.resources, [record]);
    expect(index.rebuiltWith, [record]);
    expect(repository.openCount, 1);
  });

  test('missing last path clears the setting and stays closed', () async {
    final settings = MemoryAppSettings(lastVaultPath: null);
    final controller = VaultController(
      repository: FakeVaultRepository.opening(handle),
      scan: FakeResourceScanner(const []).scan,
      index: RecordingSearchIndex(),
      settings: settings,
      watch: (_) => const Stream.empty(),
    );
    addTearDown(controller.dispose);

    await controller.restoreLastVault();

    expect(controller.state, isA<VaultClosed>());
    expect(settings.writeCount, 0);
  });

  test('invalid last path clears setting and returns closed', () async {
    final missing = Directory('/tmp/nightelf-missing-vault-path');
    final settings = MemoryAppSettings(lastVaultPath: missing.path);
    final controller = VaultController(
      repository: FakeVaultRepository.failingOpen(
        const InvalidVaultException('missing'),
      ),
      scan: FakeResourceScanner(const []).scan,
      index: RecordingSearchIndex(),
      settings: settings,
      watch: (_) => const Stream.empty(),
    );
    addTearDown(controller.dispose);

    await controller.restoreLastVault();

    expect(controller.state, isA<VaultClosed>());
    expect(settings.lastVaultPath, isNull);
    expect(settings.writeCount, 1);
  });

  test('createVault opens, scans, indexes, and remembers the path', () async {
    final record = mcpRecord(id: 'm1');
    final index = RecordingSearchIndex();
    final settings = MemoryAppSettings();
    final controller = VaultController(
      repository: FakeVaultRepository.opening(handle),
      scan: FakeResourceScanner([record]).scan,
      index: index,
      settings: settings,
      watch: (_) => const Stream.empty(),
    );
    addTearDown(controller.dispose);

    await controller.createVault(root, '工作资源');

    expect(controller.state, isA<VaultOpen>());
    expect((controller.state as VaultOpen).resources, [record]);
    expect(index.rebuiltWith, [record]);
    expect(settings.lastVaultPath, root.path);
  });

  test(
    'openVault failure keeps a Chinese error and does not wipe the folder',
    () async {
      final settings = MemoryAppSettings();
      final controller = VaultController(
        repository: FakeVaultRepository.failingOpen(
          const InvalidVaultException('bad marker'),
        ),
        scan: FakeResourceScanner(const []).scan,
        index: RecordingSearchIndex(),
        settings: settings,
        watch: (_) => const Stream.empty(),
      );
      addTearDown(controller.dispose);

      await controller.openVault(root);

      expect(controller.state, isA<VaultFailure>());
      expect((controller.state as VaultFailure).message, contains('无法打开'));
      expect(settings.lastVaultPath, isNull);
      expect(await root.exists(), isTrue);
    },
  );

  test('refreshPaths rescans and rebuilds the index', () async {
    final first = promptRecord(id: 'p1');
    final second = promptRecord(id: 'p2', title: '新提示词');
    final scanner = FakeResourceScanner([first]);
    final index = RecordingSearchIndex();
    final controller = VaultController(
      repository: FakeVaultRepository.opening(handle),
      scan: scanner.scan,
      index: index,
      settings: MemoryAppSettings(lastVaultPath: root.path),
      watch: (_) => const Stream.empty(),
    );
    addTearDown(controller.dispose);
    await controller.openVault(root);

    scanner.records = [first, second];
    await controller.refreshPaths({'prompts/new.md'});

    expect((controller.state as VaultOpen).resources, [first, second]);
    expect(index.rebuiltWith, [first, second]);
  });
}
