import 'dart:io';

import 'package:ai_workbench/features/vault/domain/vault_handle.dart';

abstract interface class VaultRepository {
  Future<VaultHandle> create(Directory root, String name);

  Future<VaultHandle> open(Directory root);
}

class InvalidVaultException implements Exception {
  const InvalidVaultException([this.message = 'Invalid Vault marker']);

  final String message;

  @override
  String toString() => 'InvalidVaultException: $message';
}

class UnsupportedVaultVersionException implements Exception {
  const UnsupportedVaultVersionException(this.version);

  final int version;

  @override
  String toString() => 'UnsupportedVaultVersionException: $version';
}

class VaultAlreadyExistsException implements Exception {
  const VaultAlreadyExistsException(this.path);

  final String path;

  @override
  String toString() => 'VaultAlreadyExistsException: $path';
}
