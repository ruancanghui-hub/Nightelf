import 'dart:convert';
import 'dart:io';

import 'package:ai_workbench/features/metadata/data/metadata_repository.dart';
import 'package:ai_workbench/features/metadata/domain/resource_metadata.dart';
import 'package:ai_workbench/features/vault/data/vault_paths.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:path/path.dart' as p;

/// Persists favorites, collections, resource metadata, and recent items.
class JsonMetadataRepository implements MetadataRepository {
  JsonMetadataRepository({
    required Directory vaultRoot,
    AtomicFileWriter? writer,
    this.recentLimit = 50,
  }) : _favoritesFile = File(
         p.join(vaultRoot.path, VaultPaths.metadataRoot, 'favorites.json'),
       ),
       _collectionsFile = File(
         p.join(vaultRoot.path, VaultPaths.metadataRoot, 'collections.json'),
       ),
       _metadataFile = File(
         p.join(vaultRoot.path, VaultPaths.resourceMetadata, 'metadata.json'),
       ),
       _recentFile = File(
         p.join(vaultRoot.path, VaultPaths.localRoot, 'recent.json'),
       ),
       _writer = writer ?? AtomicFileWriter();

  static const _version = 1;

  final File _favoritesFile;
  final File _collectionsFile;
  final File _metadataFile;
  final File _recentFile;
  final AtomicFileWriter _writer;
  final int recentLimit;

  @override
  Future<MetadataSnapshot> load() async {
    final favoriteIds = await _loadFavoriteIds();
    final resources = await _loadResources(favoriteIds);
    final collections = await _loadCollections();
    final recent = await _loadRecentIds();
    return MetadataSnapshot(
      resources: resources,
      collections: collections,
      recentResourceIds: recent,
    );
  }

  @override
  Future<void> saveResource(ResourceMetadata metadata) async {
    final snapshot = await load();
    final resources = Map<String, ResourceMetadata>.from(snapshot.resources);
    final normalized = _normalizeResource(metadata);
    resources[normalized.resourceId] = normalized;

    await _writeResources(resources);
    await _writeFavoriteIds({
      for (final entry in resources.entries)
        if (entry.value.isFavorite) entry.key,
    });
  }

  @override
  Future<void> saveCollection(CollectionRecord collection) async {
    final snapshot = await load();
    final name = collection.name.trim();
    if (name.isEmpty) {
      throw ArgumentError('集合名称不能为空');
    }
    final duplicate = snapshot.collections.any(
      (item) =>
          item.id != collection.id &&
          item.name.trim().toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) {
      throw StateError('集合名称已存在：$name');
    }

    final collections = List<CollectionRecord>.from(snapshot.collections);
    final index = collections.indexWhere((item) => item.id == collection.id);
    final next = collection.copyWith(
      name: name,
      resourceIds: _dedupePreserveOrder(collection.resourceIds),
    );
    if (index < 0) {
      collections.add(next);
    } else {
      collections[index] = next;
    }
    await _writeCollections(collections);
  }

  @override
  Future<void> deleteCollection(String collectionId) async {
    final snapshot = await load();
    final collections = snapshot.collections
        .where((item) => item.id != collectionId)
        .toList();
    await _writeCollections(collections);
  }

  @override
  Future<void> recordRecent(String resourceId) async {
    final existing = await _loadRecentIds();
    final next = <String>[
      resourceId,
      ...existing.where((id) => id != resourceId),
    ];
    if (next.length > recentLimit) {
      next.removeRange(recentLimit, next.length);
    }
    await _writeRecentIds(next);
  }

  Future<Set<String>> _loadFavoriteIds() async {
    final decoded = await _readJsonMap(_favoritesFile);
    final ids = decoded?['resourceIds'];
    if (ids is! List) {
      return <String>{};
    }
    return ids.whereType<String>().toSet();
  }

  Future<Map<String, ResourceMetadata>> _loadResources(
    Set<String> favoriteIds,
  ) async {
    final decoded = await _readJsonMap(_metadataFile);
    final raw = decoded?['resources'];
    final result = <String, ResourceMetadata>{};
    if (raw is Map) {
      final keys = raw.keys.map((key) => '$key').toList()..sort();
      for (final key in keys) {
        final value = raw[key];
        if (value is! Map) {
          continue;
        }
        final related = value['relatedResourceIds'];
        final tags = value['tags'];
        result[key] = ResourceMetadata(
          resourceId: key,
          description: value['description'] is String
              ? value['description'] as String
              : '',
          tags: tags is List
              ? tags.whereType<String>().toList(growable: false)
              : const [],
          relatedResourceIds: related is List
              ? related.whereType<String>().toList(growable: false)
              : const [],
          isFavorite: favoriteIds.contains(key),
        );
      }
    }
    for (final id in favoriteIds) {
      result.putIfAbsent(
        id,
        () => ResourceMetadata(resourceId: id, isFavorite: true),
      );
    }
    return result;
  }

  Future<List<CollectionRecord>> _loadCollections() async {
    final decoded = await _readJsonMap(_collectionsFile);
    final raw = decoded?['collections'];
    if (raw is! List) {
      return const [];
    }
    final collections = <CollectionRecord>[];
    for (final item in raw) {
      if (item is! Map) {
        continue;
      }
      final id = item['id'];
      final name = item['name'];
      if (id is! String || name is! String) {
        continue;
      }
      final resourceIds = item['resourceIds'];
      collections.add(
        CollectionRecord(
          id: id,
          name: name,
          resourceIds: resourceIds is List
              ? resourceIds.whereType<String>().toList(growable: false)
              : const [],
        ),
      );
    }
    return collections;
  }

  Future<List<String>> _loadRecentIds() async {
    final decoded = await _readJsonMap(_recentFile);
    final ids = decoded?['resourceIds'];
    if (ids is! List) {
      return const [];
    }
    return ids.whereType<String>().toList(growable: false);
  }

  Future<void> _writeFavoriteIds(Set<String> ids) async {
    await _favoritesFile.parent.create(recursive: true);
    final ordered = ids.toList()..sort();
    await _writeJson(_favoritesFile, {
      'version': _version,
      'resourceIds': ordered,
    });
  }

  Future<void> _writeResources(Map<String, ResourceMetadata> resources) async {
    await _metadataFile.parent.create(recursive: true);
    final keys = resources.keys.toList()..sort();
    final encoded = <String, Object?>{};
    for (final key in keys) {
      final meta = resources[key]!;
      encoded[key] = {
        'description': meta.description,
        'tags': meta.tags,
        'relatedResourceIds': meta.relatedResourceIds,
      };
    }
    await _writeJson(_metadataFile, {
      'version': _version,
      'resources': encoded,
    });
  }

  Future<void> _writeCollections(List<CollectionRecord> collections) async {
    await _collectionsFile.parent.create(recursive: true);
    await _writeJson(_collectionsFile, {
      'version': _version,
      'collections': [
        for (final collection in collections)
          {
            'id': collection.id,
            'name': collection.name,
            'resourceIds': collection.resourceIds,
          },
      ],
    });
  }

  Future<void> _writeRecentIds(List<String> ids) async {
    await _recentFile.parent.create(recursive: true);
    await _writeJson(_recentFile, {'version': _version, 'resourceIds': ids});
  }

  Future<Map<String, Object?>?> _readJsonMap(File file) async {
    if (!await file.exists()) {
      return null;
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        return null;
      }
      return decoded.map((key, value) => MapEntry('$key', value));
    } on FormatException {
      return null;
    }
  }

  Future<void> _writeJson(File file, Map<String, Object?> payload) async {
    final encoded = jsonEncode(payload);
    await _writer.writeString(file, '$encoded\n');
  }

  ResourceMetadata _normalizeResource(ResourceMetadata metadata) {
    return metadata.copyWith(
      description: metadata.description.trim(),
      tags: _normalizeTags(metadata.tags),
      relatedResourceIds: _dedupePreserveOrder(metadata.relatedResourceIds),
    );
  }

  List<String> _normalizeTags(List<String> tags) {
    final seen = <String>{};
    final result = <String>[];
    for (final tag in tags) {
      final trimmed = tag.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final key = trimmed.toLowerCase();
      if (seen.add(key)) {
        result.add(trimmed);
      }
    }
    return result;
  }

  List<String> _dedupePreserveOrder(List<String> ids) {
    final seen = <String>{};
    final result = <String>[];
    for (final id in ids) {
      if (id.isEmpty) {
        continue;
      }
      if (seen.add(id)) {
        result.add(id);
      }
    }
    return result;
  }
}
