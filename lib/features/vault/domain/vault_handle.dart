import 'dart:io';

import 'vault_manifest.dart';

/// An opened Vault and the manifest that identifies it.
class VaultHandle {
  const VaultHandle(this.root, this.manifest);

  final Directory root;
  final VaultManifest manifest;

  String get id => manifest.id;
  String get name => manifest.name;
}
