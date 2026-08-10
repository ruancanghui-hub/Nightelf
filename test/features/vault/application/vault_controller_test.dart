import 'dart:io';

import 'package:ai_workbench/features/vault/application/vault_controller.dart';
import 'package:ai_workbench/features/vault/application/vault_state.dart';
import 'package:ai_workbench/features/vault/data/vault_repository.dart';
import 'package:ai_workbench/features/vault/domain/vault_handle.dart';
import 'package:ai_workbench/features/vault/domain/vault_manifest.dart';
import 'package:ai_workbench/shared/platform/directory_picker_service.dart';
import 'package:ai_workbench/shared/platform/folder_icon_service.dart';
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
    final icons = RecordingFolderIconService();
    final controller = VaultController(
      repository: repository,
      scan: scanner.scan,
      index: index,
      settings: settings,
      watch: (_) => const Stream.empty(),
      vaultAccess: NoopDirectoryPickerService(),
      folderIcons: icons,
    );
    addTearDown(controller.dispose);

    await controller.restoreLastVault();

    expect(controller.state, isA<VaultOpen>());
    final open = controller.state as VaultOpen;
    expect(open.handle, handle);
    expect(open.resources, [record]);
    expect(index.rebuiltWith, [record]);
    expect(repository.openCount, 1);
    expect(icons.paths, [handle.root.path]);
  });

  test('restores via security-scoped bookmark when present', () async {
    final record = promptRecord(id: 'p1');
    final access = RecordingDirectoryPickerService()
      ..nextResolved = PickedDirectory(
        path: handle.root.path,
        bookmarkBase64: 'refreshed-bookmark',
      );
    final settings = MemoryAppSettings(
      lastVaultPath: '/stale/path',
      lastVaultBookmark: 'saved-bookmark',
    );
    final controller = VaultController(
      repository: FakeVaultRepository.opening(handle),
      scan: FakeResourceScanner([record]).scan,
      index: RecordingSearchIndex(),
      settings: settings,
      watch: (_) => const Stream.empty(),
      vaultAccess: access,
      folderIcons: NoopFolderIconService(),
    );
    addTearDown(controller.dispose);

    await controller.restoreLastVault();

    expect(controller.state, isA<VaultOpen>());
    expect(access.resolveCalls, ['saved-bookmark']);
    expect(settings.lastVaultPath, handle.root.path);
    expect(settings.lastVaultBookmark, 'refreshed-bookmark');
  });

  test('missing last path clears the setting and stays closed', () async {
    final settings = MemoryAppSettings(lastVaultPath: null);
    final controller = VaultController(
      repository: FakeVaultRepository.opening(handle),
      scan: FakeResourceScanner(const []).scan,
      index: RecordingSearchIndex(),
      settings: settings,
      watch: (_) => const Stream.empty(),
      vaultAccess: NoopDirectoryPickerService(),
      folderIcons: NoopFolderIconService(),
    );
    addTearDown(controller.dispose);

    await controller.restoreLastVault();

    expect(controller.state, isA<VaultClosed>());
    expect(settings.writeCount, 0);
  });

  test('missing directory clears setting and returns closed', () async {
    final missing = Directory('/tmp/nightelf-missing-vault-path-${root.path.hashCode}');
    final settings = MemoryAppSettings(lastVaultPath: missing.path);
    final controller = VaultController(
      repository: FakeVaultRepository.failingOpen(
        const InvalidVaultException('missing'),
      ),
      scan: FakeResourceScanner(const []).scan,
      index: RecordingSearchIndex(),
      settings: settings,
      watch: (_) => const Stream.empty(),
      vaultAccess: NoopDirectoryPickerService(),
      folderIcons: NoopFolderIconService(),
    );
    addTearDown(controller.dispose);

    await controller.restoreLastVault();

    expect(controller.state, isA<VaultClosed>());
    expect(settings.lastVaultPath, isNull);
    expect(settings.writeCount, 1);
  });

  test('restore open failure keeps prefs and shows recoverable failure', () async {
    final settings = MemoryAppSettings(lastVaultPath: root.path);
    final controller = VaultController(
      repository: FakeVaultRepository.failingOpen(
        const InvalidVaultException('missing'),
      ),
      scan: FakeResourceScanner(const []).scan,
      index: RecordingSearchIndex(),
      settings: settings,
      watch: (_) => const Stream.empty(),
      vaultAccess: NoopDirectoryPickerService(),
      folderIcons: NoopFolderIconService(),
    );
    addTearDown(controller.dispose);

    await controller.restoreLastVault();

    expect(controller.state, isA<VaultFailure>());
    expect(
      (controller.state as VaultFailure).message,
      contains('无法打开上次 Vault'),
    );
    expect(settings.lastVaultPath, root.path);
  });

  test('createVault opens, scans, indexes, and remembers path+bookmark', () async {
    final record = mcpRecord(id: 'm1');
    final index = RecordingSearchIndex();
    final settings = MemoryAppSettings();
    final icons = RecordingFolderIconService();
    final controller = VaultController(
      repository: FakeVaultRepository.opening(handle),
      scan: FakeResourceScanner([record]).scan,
      index: index,
      settings: settings,
      watch: (_) => const Stream.empty(),
      vaultAccess: NoopDirectoryPickerService(),
      folderIcons: icons,
    );
    addTearDown(controller.dispose);

    await controller.createVault(
      root,
      '工作资源',
      bookmarkBase64: 'create-bookmark',
    );

    expect(controller.state, isA<VaultOpen>());
    expect((controller.state as VaultOpen).resources, [record]);
    expect(index.rebuiltWith, [record]);
    expect(settings.lastVaultPath, root.path);
    expect(settings.lastVaultBookmark, 'create-bookmark');
    expect(icons.paths, [root.path]);
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
        vaultAccess: NoopDirectoryPickerService(),
        folderIcons: NoopFolderIconService(),
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
      vaultAccess: NoopDirectoryPickerService(),
      folderIcons: NoopFolderIconService(),
    );
    addTearDown(controller.dispose);
    await controller.openVault(root);

    scanner.records = [first, second];
    await controller.refreshPaths({'prompts/new.md'});

    expect((controller.state as VaultOpen).resources, [first, second]);
    expect(index.rebuiltWith, [first, second]);
  });
}
