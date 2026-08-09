import 'package:ai_workbench/features/metadata/application/metadata_controller.dart';
import 'package:ai_workbench/features/metadata/data/metadata_repository.dart';
import 'package:ai_workbench/features/metadata/domain/resource_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryMetadataRepository implements MetadataRepository {
  MetadataSnapshot snapshot = const MetadataSnapshot();
  int recentLimit = 50;

  @override
  Future<MetadataSnapshot> load() async => snapshot;

  @override
  Future<void> saveResource(ResourceMetadata metadata) async {
    final resources = Map<String, ResourceMetadata>.from(snapshot.resources);
    final tags = <String>[];
    final seen = <String>{};
    for (final tag in metadata.tags) {
      final trimmed = tag.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      if (seen.add(trimmed.toLowerCase())) {
        tags.add(trimmed);
      }
    }
    resources[metadata.resourceId] = metadata.copyWith(
      description: metadata.description.trim(),
      tags: tags,
    );
    snapshot = MetadataSnapshot(
      resources: resources,
      collections: snapshot.collections,
      recentEntries: snapshot.recentEntries,
    );
  }

  @override
  Future<void> saveCollection(CollectionRecord collection) async {
    final name = collection.name.trim();
    if (snapshot.collections.any(
      (item) =>
          item.id != collection.id &&
          item.name.trim().toLowerCase() == name.toLowerCase(),
    )) {
      throw StateError('集合名称已存在：$name');
    }
    final collections = List<CollectionRecord>.from(snapshot.collections);
    final index = collections.indexWhere((item) => item.id == collection.id);
    final next = collection.copyWith(name: name);
    if (index < 0) {
      collections.add(next);
    } else {
      collections[index] = next;
    }
    snapshot = MetadataSnapshot(
      resources: snapshot.resources,
      collections: collections,
      recentEntries: snapshot.recentEntries,
    );
  }

  @override
  Future<void> deleteCollection(String collectionId) async {
    snapshot = MetadataSnapshot(
      resources: snapshot.resources,
      collections: snapshot.collections
          .where((item) => item.id != collectionId)
          .toList(),
      recentEntries: snapshot.recentEntries,
    );
  }

  @override
  Future<void> recordRecent(String resourceId) async {
    final next = <RecentResourceEntry>[
      RecentResourceEntry(resourceId: resourceId, openedAt: DateTime.now()),
      ...snapshot.recentEntries.where((entry) => entry.resourceId != resourceId),
    ];
    if (next.length > recentLimit) {
      next.removeRange(recentLimit, next.length);
    }
    snapshot = MetadataSnapshot(
      resources: snapshot.resources,
      collections: snapshot.collections,
      recentEntries: next,
    );
  }
}

void main() {
  test('favorite toggle is idempotent across reloads', () async {
    final repo = _MemoryMetadataRepository();
    final controller = MetadataController(
      repository: repo,
      idFactory: () => 'col-1',
    );
    await controller.load();
    await controller.toggleFavorite('workflow-1');
    expect(controller.favoriteIds, {'workflow-1'});
    await controller.toggleFavorite('workflow-1');
    expect(controller.favoriteIds, isEmpty);
    await controller.setFavorite('workflow-1', true);
    await controller.setFavorite('workflow-1', true);
    expect(controller.favoriteIds, {'workflow-1'});
  });

  test('tags are trimmed and deduplicated by controller', () async {
    final repo = _MemoryMetadataRepository();
    final controller = MetadataController(repository: repo);
    await controller.load();
    await controller.updateTags('prompt-1', [' 内容 ', '内容', '发布', '']);
    expect(controller.metadataFor('prompt-1').tags, ['内容', '发布']);
  });

  test('recent list caps at 50', () async {
    final repo = _MemoryMetadataRepository()..recentLimit = 50;
    final controller = MetadataController(repository: repo);
    await controller.load();
    for (var i = 0; i < 55; i += 1) {
      await controller.recordRecent('id-$i');
    }
    expect(controller.recentResourceIds.length, 50);
    expect(controller.recentResourceIds.first, 'id-54');
    expect(controller.recentResourceIds.last, 'id-5');
  });

  test('collection CRUD rejects duplicate names and keeps resources', () async {
    final repo = _MemoryMetadataRepository();
    var nextId = 0;
    final controller = MetadataController(
      repository: repo,
      idFactory: () => 'col-${nextId++}',
    );
    await controller.load();
    await controller.setFavorite('prompt-1', true);
    final created = await controller.createCollection('发布');
    await controller.addResourceToCollection(created.id, 'prompt-1');
    await controller.addResourceToCollection(created.id, 'missing-1');

    expect(() => controller.createCollection('发布'), throwsA(isA<StateError>()));

    await controller.deleteCollection(created.id);
    expect(controller.collections, isEmpty);
    expect(controller.favoriteIds, {'prompt-1'});
  });

  test('missing related refs render as 缺失资源 without auto-delete', () async {
    final repo = _MemoryMetadataRepository();
    final controller = MetadataController(repository: repo);
    await controller.load();
    await controller.setRelatedResourceIds('prompt-1', ['gone-1', 'live-1']);
    final refs = controller.relatedRefsFor(
      'prompt-1',
      titleLookup: (id) => id == 'live-1' ? '存活资源' : null,
    );
    expect(refs.map((ref) => ref.title), ['缺失资源', '存活资源']);
    expect(refs.first.isMissing, isTrue);
    expect(controller.metadataFor('prompt-1').relatedResourceIds, [
      'gone-1',
      'live-1',
    ]);

    await controller.relinkRelatedResource(
      resourceId: 'prompt-1',
      missingId: 'gone-1',
      replacementId: 'live-2',
    );
    expect(controller.metadataFor('prompt-1').relatedResourceIds, [
      'live-2',
      'live-1',
    ]);
  });
}
