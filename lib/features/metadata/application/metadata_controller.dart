import 'package:ai_workbench/features/metadata/data/metadata_repository.dart';
import 'package:ai_workbench/features/metadata/domain/resource_metadata.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// A related resource row for the inspector, including missing references.
class RelatedResourceRef {
  const RelatedResourceRef({
    required this.resourceId,
    required this.title,
    required this.isMissing,
  });

  final String resourceId;
  final String title;
  final bool isMissing;
}

/// Owns Vault-scoped metadata mutations and in-memory snapshot.
class MetadataController extends ChangeNotifier {
  MetadataController({
    required MetadataRepository repository,
    String Function()? idFactory,
  }) : _repository = repository,
       _idFactory = idFactory ?? const Uuid().v4;

  final MetadataRepository _repository;
  final String Function() _idFactory;

  MetadataSnapshot _snapshot = const MetadataSnapshot();
  bool _loaded = false;

  MetadataSnapshot get snapshot => _snapshot;

  bool get isLoaded => _loaded;

  Set<String> get favoriteIds => _snapshot.favoriteIds;

  List<CollectionRecord> get collections => _snapshot.collections;

  List<String> get recentResourceIds => _snapshot.recentResourceIds;

  List<RecentResourceEntry> get recentEntries => _snapshot.recentEntries;

  ResourceMetadata metadataFor(String resourceId) {
    return _snapshot.resources[resourceId] ??
        ResourceMetadata(resourceId: resourceId);
  }

  Future<void> load() async {
    _snapshot = await _repository.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggleFavorite(String resourceId) async {
    final current = metadataFor(resourceId);
    final next = current.copyWith(isFavorite: !current.isFavorite);
    await _repository.saveResource(next);
    await load();
  }

  Future<void> setFavorite(String resourceId, bool isFavorite) async {
    final current = metadataFor(resourceId);
    if (current.isFavorite == isFavorite &&
        _snapshot.resources.containsKey(resourceId)) {
      return;
    }
    await _repository.saveResource(current.copyWith(isFavorite: isFavorite));
    await load();
  }

  Future<void> updateDescription(String resourceId, String description) async {
    final current = metadataFor(resourceId);
    final trimmed = description.trim();
    if (current.description == trimmed) {
      return;
    }
    await _repository.saveResource(current.copyWith(description: trimmed));
    await load();
  }

  Future<void> updateTags(String resourceId, List<String> tags) async {
    final current = metadataFor(resourceId);
    final normalized = _normalizeTags(tags);
    if (listEquals(current.tags, normalized)) {
      return;
    }
    await _repository.saveResource(current.copyWith(tags: normalized));
    await load();
  }

  Future<void> setRelatedResourceIds(
    String resourceId,
    List<String> relatedResourceIds,
  ) async {
    final current = metadataFor(resourceId);
    final next = _dedupe(relatedResourceIds);
    if (listEquals(current.relatedResourceIds, next)) {
      return;
    }
    await _repository.saveResource(current.copyWith(relatedResourceIds: next));
    await load();
  }

  Future<void> removeRelatedResource(
    String resourceId,
    String relatedId,
  ) async {
    final current = metadataFor(resourceId);
    final next = current.relatedResourceIds
        .where((id) => id != relatedId)
        .toList();
    await setRelatedResourceIds(resourceId, next);
  }

  Future<void> relinkRelatedResource({
    required String resourceId,
    required String missingId,
    required String replacementId,
  }) async {
    final current = metadataFor(resourceId);
    final next = [
      for (final id in current.relatedResourceIds)
        if (id == missingId) replacementId else id,
    ];
    await setRelatedResourceIds(resourceId, next);
  }

  List<RelatedResourceRef> relatedRefsFor(
    String resourceId, {
    required String? Function(String id) titleLookup,
  }) {
    final related = metadataFor(resourceId).relatedResourceIds;
    return [
      for (final id in related)
        () {
          final title = titleLookup(id);
          if (title == null) {
            return RelatedResourceRef(
              resourceId: id,
              title: '缺失资源',
              isMissing: true,
            );
          }
          return RelatedResourceRef(
            resourceId: id,
            title: title,
            isMissing: false,
          );
        }(),
    ];
  }

  Future<void> recordRecent(String resourceId) async {
    await _repository.recordRecent(resourceId);
    await load();
  }

  Future<CollectionRecord> createCollection(String name) async {
    final collection = CollectionRecord(id: _idFactory(), name: name);
    await _repository.saveCollection(collection);
    await load();
    return _snapshot.collections.firstWhere((item) => item.id == collection.id);
  }

  Future<void> renameCollection(String collectionId, String name) async {
    final existing = _snapshot.collections.firstWhere(
      (item) => item.id == collectionId,
    );
    await _repository.saveCollection(existing.copyWith(name: name));
    await load();
  }

  Future<void> deleteCollection(String collectionId) async {
    await _repository.deleteCollection(collectionId);
    await load();
  }

  Future<void> setCollectionMembers(
    String collectionId,
    List<String> resourceIds,
  ) async {
    final existing = _snapshot.collections.firstWhere(
      (item) => item.id == collectionId,
    );
    await _repository.saveCollection(
      existing.copyWith(resourceIds: _dedupe(resourceIds)),
    );
    await load();
  }

  Future<void> addResourceToCollection(
    String collectionId,
    String resourceId,
  ) async {
    final existing = _snapshot.collections.firstWhere(
      (item) => item.id == collectionId,
    );
    if (existing.resourceIds.contains(resourceId)) {
      return;
    }
    await setCollectionMembers(collectionId, [
      ...existing.resourceIds,
      resourceId,
    ]);
  }

  Future<void> removeResourceFromCollection(
    String collectionId,
    String resourceId,
  ) async {
    final existing = _snapshot.collections.firstWhere(
      (item) => item.id == collectionId,
    );
    await setCollectionMembers(
      collectionId,
      existing.resourceIds.where((id) => id != resourceId).toList(),
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
      if (seen.add(trimmed.toLowerCase())) {
        result.add(trimmed);
      }
    }
    return result;
  }

  List<String> _dedupe(List<String> ids) {
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
