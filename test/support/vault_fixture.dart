import 'dart:io';

import 'package:ai_workbench/features/vault/data/file_vault_repository.dart';
import 'package:ai_workbench/features/vault/data/resource_scanner.dart';
import 'package:ai_workbench/features/vault/domain/vault_handle.dart';
import 'package:path/path.dart' as p;

class VaultFixture {
  VaultFixture({
    required this.root,
    required this.handle,
    required this.scanner,
  });

  final Directory root;
  final VaultHandle handle;
  final ResourceScanner scanner;

  Future<void> dispose() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  }
}

Future<VaultFixture> createVaultFixture(Map<String, String> files) async {
  final root = await Directory.systemTemp.createTemp('nightelf-scan-vault-');
  try {
    final handle = await FileVaultRepository(
      idFactory: () => 'fixture-vault',
    ).create(root, 'Fixture Vault');
    for (final entry in files.entries) {
      final file = File(p.join(root.path, entry.key));
      await file.parent.create(recursive: true);
      await file.writeAsString(entry.value);
    }
    return VaultFixture(root: root, handle: handle, scanner: ResourceScanner());
  } catch (_) {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
    rethrow;
  }
}
