import 'dart:convert';
import 'dart:io';

import 'package:ai_workbench/features/metadata/data/favorites_repository.dart';
import 'package:ai_workbench/features/vault/data/vault_paths.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:path/path.dart' as p;

/// Persists favorite resource IDs inside the open Vault.
///
/// Each Vault has its own `.ai-workbench/favorites.json`, so favorites never
/// leak across workspaces.
class JsonFavoritesRepository implements FavoritesRepository {
  JsonFavoritesRepository({
    required Directory vaultRoot,
    AtomicFileWriter? writer,
  }) : _file = File(
         p.join(vaultRoot.path, VaultPaths.metadataRoot, 'favorites.json'),
       ),
       _writer = writer ?? AtomicFileWriter();

  static const _version = 1;

  final File _file;
  final AtomicFileWriter _writer;

  @override
  Future<Set<String>> loadFavoriteIds() async {
    if (!await _file.exists()) {
      return <String>{};
    }
    try {
      final decoded = jsonDecode(await _file.readAsString());
      if (decoded is! Map) {
        return <String>{};
      }
      final ids = decoded['resourceIds'];
      if (ids is! List) {
        return <String>{};
      }
      return ids.whereType<String>().toSet();
    } on FormatException {
      return <String>{};
    }
  }

  @override
  Future<void> saveFavoriteIds(Set<String> ids) async {
    await _file.parent.create(recursive: true);
    final ordered = ids.toList()..sort();
    final payload = jsonEncode({'version': _version, 'resourceIds': ordered});
    await _writer.writeString(_file, '$payload\n');
  }
}
