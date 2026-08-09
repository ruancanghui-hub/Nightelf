import 'dart:convert';
import 'dart:io';

import 'package:ai_workbench/features/vault/data/vault_paths.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class ResourceIdentityStore {
  ResourceIdentityStore(
    Directory vaultRoot, {
    AtomicFileWriter? writer,
    String Function()? idFactory,
  }) : _indexFile = File(
         p.join(vaultRoot.path, VaultPaths.resourceMetadata, 'index.json'),
       ),
       _writer = writer ?? AtomicFileWriter(),
       _idFactory = idFactory ?? const Uuid().v4;

  final File _indexFile;
  final AtomicFileWriter _writer;
  final String Function() _idFactory;

  Map<String, String>? _identities;

  Future<String> resolve({
    required ResourceType type,
    required String relativePath,
    String? embeddedId,
  }) async {
    final normalizedEmbeddedId = embeddedId?.trim();
    if (normalizedEmbeddedId != null && normalizedEmbeddedId.isNotEmpty) {
      return normalizedEmbeddedId;
    }

    final identities = await _load();
    final key = '${type.name}:$relativePath';
    final existing = identities[key];
    if (existing != null) {
      return existing;
    }

    final id = _idFactory();
    identities[key] = id;
    await _persist(identities);
    return id;
  }

  Future<Map<String, String>> _load() async {
    final cached = _identities;
    if (cached != null) {
      return cached;
    }
    if (!await _indexFile.exists()) {
      return _identities = <String, String>{};
    }

    final decoded = jsonDecode(await _indexFile.readAsString());
    if (decoded is! Map<String, Object?> || decoded['version'] != 1) {
      throw const FormatException('Invalid resource identity index');
    }
    final encodedIdentities = decoded['identities'];
    if (encodedIdentities is! Map<String, Object?>) {
      throw const FormatException('Invalid resource identity mappings');
    }
    final identities = <String, String>{};
    for (final entry in encodedIdentities.entries) {
      if (entry.value is! String) {
        throw const FormatException('Invalid resource identity');
      }
      identities[entry.key] = entry.value! as String;
    }
    return _identities = identities;
  }

  Future<void> _persist(Map<String, String> identities) async {
    await _indexFile.parent.create(recursive: true);
    final sortedKeys = identities.keys.toList()..sort();
    final sorted = <String, String>{
      for (final key in sortedKeys) key: identities[key]!,
    };
    await _writer.writeString(
      _indexFile,
      jsonEncode(<String, Object?>{'version': 1, 'identities': sorted}),
    );
  }
}
