import 'dart:convert';
import 'dart:io';

import 'package:ai_workbench/features/vault/data/vault_paths.dart';
import 'package:ai_workbench/features/vault/data/vault_repository.dart';
import 'package:ai_workbench/features/vault/domain/vault_handle.dart';
import 'package:ai_workbench/features/vault/domain/vault_manifest.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

export 'vault_repository.dart';

const _supportedVaultVersion = 1;
const _standardDirectories = <String>[
  'prompts',
  'skills',
  'mcp',
  'links',
  'workflows',
  'launchers',
  'assets',
];
const _gitignoreContents = '''.ai-workbench/local/
.env
.env.*
*.nightelf-tmp
''';

String _newVaultId() => const Uuid().v4();

class FileVaultRepository implements VaultRepository {
  FileVaultRepository({AtomicFileWriter? writer, String Function()? idFactory})
    : _writer = writer ?? AtomicFileWriter(),
      _idFactory = idFactory ?? _newVaultId;

  final AtomicFileWriter _writer;
  final String Function() _idFactory;

  @override
  Future<VaultHandle> create(Directory root, String name) async {
    await root.create(recursive: true);
    final marker = File(p.join(root.path, VaultPaths.marker));
    if (await marker.exists()) {
      throw VaultAlreadyExistsException(root.path);
    }

    for (final name in _standardDirectories) {
      await Directory(p.join(root.path, name)).create(recursive: true);
    }
    await Directory(
      p.join(root.path, VaultPaths.localRoot),
    ).create(recursive: true);

    await _writer.writeString(
      File(p.join(root.path, '.gitignore')),
      _gitignoreContents,
    );
    final manifest = VaultManifest(
      version: _supportedVaultVersion,
      id: _idFactory(),
      name: name,
    );
    await _writer.writeString(marker, jsonEncode(manifest.toJson()));

    return VaultHandle(root, manifest);
  }

  @override
  Future<VaultHandle> open(Directory root) async {
    final marker = File(p.join(root.path, VaultPaths.marker));
    if (!await marker.exists()) {
      throw const InvalidVaultException('Vault marker is missing');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(await marker.readAsString());
    } on FormatException {
      throw const InvalidVaultException('Vault marker is malformed');
    } on FileSystemException {
      throw const InvalidVaultException('Vault marker cannot be read');
    }
    if (decoded is! Map<String, Object?>) {
      throw const InvalidVaultException('Vault marker must be a JSON object');
    }

    final version = decoded['version'];
    if (version is! int) {
      throw const InvalidVaultException('Vault version is invalid');
    }
    if (version != _supportedVaultVersion) {
      throw UnsupportedVaultVersionException(version);
    }
    if (decoded['id'] is! String || decoded['name'] is! String) {
      throw const InvalidVaultException('Vault manifest fields are invalid');
    }

    return VaultHandle(root, VaultManifest.fromJson(decoded));
  }
}
