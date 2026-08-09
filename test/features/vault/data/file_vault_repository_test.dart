import 'dart:convert';
import 'dart:io';

import 'package:ai_workbench/features/vault/data/file_vault_repository.dart';
import 'package:ai_workbench/features/vault/data/vault_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileVaultRepository.create', () {
    test(
      'writes marker, standard folders, local metadata, and gitignore',
      () async {
        final root = await Directory.systemTemp.createTemp('nightelf-vault-');
        addTearDown(() => root.delete(recursive: true));
        final repository = FileVaultRepository(idFactory: () => 'vault-id');

        final handle = await repository.create(root, '工作资源');

        expect(handle.root.path, root.path);
        expect(handle.manifest.version, 1);
        expect(handle.manifest.id, 'vault-id');
        expect(handle.manifest.name, '工作资源');
        final marker = File('${root.path}/${VaultPaths.marker}');
        expect(jsonDecode(await marker.readAsString()), <String, Object?>{
          'version': 1,
          'id': 'vault-id',
          'name': '工作资源',
        });
        for (final name in [
          'prompts',
          'skills',
          'mcp',
          'links',
          'workflows',
          'assets',
        ]) {
          expect(Directory('${root.path}/$name').existsSync(), isTrue);
        }
        expect(
          Directory('${root.path}/${VaultPaths.localRoot}').existsSync(),
          isTrue,
        );
        expect(
          await File('${root.path}/.gitignore').readAsString(),
          '.ai-workbench/local/\n.env\n.env.*\n*.nightelf-tmp\n',
        );
      },
    );

    test('rejects a root that already contains a marker', () async {
      final root = await Directory.systemTemp.createTemp('nightelf-existing-');
      addTearDown(() => root.delete(recursive: true));
      await File('${root.path}/${VaultPaths.marker}').writeAsString('{}');

      expect(
        () => FileVaultRepository().create(root, 'Duplicate'),
        throwsA(isA<VaultAlreadyExistsException>()),
      );
    });
  });

  group('FileVaultRepository.open', () {
    test('returns the persisted manifest', () async {
      final root = await Directory.systemTemp.createTemp('nightelf-open-');
      addTearDown(() => root.delete(recursive: true));
      await FileVaultRepository(
        idFactory: () => 'persisted-id',
      ).create(root, '工作资源');

      final handle = await FileVaultRepository().open(root);

      expect(handle.root.path, root.path);
      expect(handle.manifest.version, 1);
      expect(handle.manifest.id, 'persisted-id');
      expect(handle.manifest.name, '工作资源');
    });

    test('rejects a directory without a marker', () async {
      final root = await Directory.systemTemp.createTemp('nightelf-invalid-');
      addTearDown(() => root.delete(recursive: true));

      expect(
        () => FileVaultRepository().open(root),
        throwsA(isA<InvalidVaultException>()),
      );
    });

    test('rejects malformed marker JSON', () async {
      final root = await Directory.systemTemp.createTemp('nightelf-malformed-');
      addTearDown(() => root.delete(recursive: true));
      await File(
        '${root.path}/${VaultPaths.marker}',
      ).writeAsString('{not-json');

      expect(
        () => FileVaultRepository().open(root),
        throwsA(isA<InvalidVaultException>()),
      );
    });

    test('rejects a marker with invalid manifest fields', () async {
      final root = await Directory.systemTemp.createTemp('nightelf-invalid-');
      addTearDown(() => root.delete(recursive: true));
      await File('${root.path}/${VaultPaths.marker}').writeAsString(
        jsonEncode(<String, Object?>{
          'version': 1,
          'id': 42,
          'name': 'Invalid',
        }),
      );

      expect(
        () => FileVaultRepository().open(root),
        throwsA(isA<InvalidVaultException>()),
      );
    });

    test('rejects an unsupported manifest version', () async {
      final root = await Directory.systemTemp.createTemp('nightelf-version-');
      addTearDown(() => root.delete(recursive: true));
      await File('${root.path}/${VaultPaths.marker}').writeAsString(
        jsonEncode(<String, Object?>{
          'version': 2,
          'id': 'vault-id',
          'name': 'Future Vault',
        }),
      );

      expect(
        () => FileVaultRepository().open(root),
        throwsA(isA<UnsupportedVaultVersionException>()),
      );
    });
  });
}
