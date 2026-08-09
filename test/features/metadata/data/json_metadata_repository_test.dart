import 'dart:io';

import 'package:ai_workbench/features/metadata/data/json_metadata_repository.dart';
import 'package:ai_workbench/features/metadata/domain/resource_metadata.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('favorite and associations survive repository reconstruction', () async {
    final root = await Directory.systemTemp.createTemp('nightelf-meta-');
    addTearDown(() => root.delete(recursive: true));
    final first = JsonMetadataRepository(
      vaultRoot: root,
      writer: AtomicFileWriter(),
    );
    await first.saveResource(
      const ResourceMetadata(
        resourceId: 'workflow-1',
        description: '发布流程',
        tags: ['内容'],
        relatedResourceIds: ['prompt-1', 'mcp-1'],
        isFavorite: true,
      ),
    );
    final snapshot = await JsonMetadataRepository(
      vaultRoot: root,
      writer: AtomicFileWriter(),
    ).load();
    expect(snapshot.resources['workflow-1']!.relatedResourceIds, [
      'prompt-1',
      'mcp-1',
    ]);
    expect(snapshot.resources['workflow-1']!.isFavorite, isTrue);
    expect(
      File(p.join(root.path, '.ai-workbench', 'favorites.json')).existsSync(),
      isTrue,
    );
    expect(
      File(
        p.join(root.path, '.ai-workbench', 'resources', 'metadata.json'),
      ).existsSync(),
      isTrue,
    );
  });

  test('missing related ids are preserved across reload', () async {
    final root = await Directory.systemTemp.createTemp('nightelf-meta-miss-');
    addTearDown(() => root.delete(recursive: true));
    final repo = JsonMetadataRepository(vaultRoot: root);
    await repo.saveResource(
      const ResourceMetadata(
        resourceId: 'prompt-1',
        relatedResourceIds: ['gone-1', 'gone-2'],
      ),
    );
    final snapshot = await repo.load();
    expect(snapshot.resources['prompt-1']!.relatedResourceIds, [
      'gone-1',
      'gone-2',
    ]);
  });

  test(
    'collections can be saved and deleted without touching resources',
    () async {
      final root = await Directory.systemTemp.createTemp('nightelf-meta-col-');
      addTearDown(() => root.delete(recursive: true));
      final repo = JsonMetadataRepository(vaultRoot: root);
      await repo.saveResource(
        const ResourceMetadata(resourceId: 'prompt-1', isFavorite: true),
      );
      await repo.saveCollection(
        const CollectionRecord(
          id: 'col-1',
          name: '发布',
          resourceIds: ['prompt-1', 'missing-1'],
        ),
      );

      var snapshot = await repo.load();
      expect(snapshot.collections.single.name, '发布');
      expect(snapshot.collections.single.resourceIds, [
        'prompt-1',
        'missing-1',
      ]);
      expect(snapshot.resources['prompt-1']!.isFavorite, isTrue);

      await repo.deleteCollection('col-1');
      snapshot = await repo.load();
      expect(snapshot.collections, isEmpty);
      expect(snapshot.resources['prompt-1']!.isFavorite, isTrue);
    },
  );

  test('duplicate collection names are rejected', () async {
    final root = await Directory.systemTemp.createTemp('nightelf-meta-dup-');
    addTearDown(() => root.delete(recursive: true));
    final repo = JsonMetadataRepository(vaultRoot: root);
    await repo.saveCollection(const CollectionRecord(id: 'a', name: '发布'));
    expect(
      () => repo.saveCollection(const CollectionRecord(id: 'b', name: ' 发布 ')),
      throwsA(isA<StateError>()),
    );
  });

  test('recent list caps at configured limit and moves to front', () async {
    final root = await Directory.systemTemp.createTemp('nightelf-meta-rec-');
    addTearDown(() => root.delete(recursive: true));
    final repo = JsonMetadataRepository(vaultRoot: root, recentLimit: 3);
    await repo.recordRecent('a');
    await repo.recordRecent('b');
    await repo.recordRecent('c');
    await repo.recordRecent('d');
    await repo.recordRecent('b');

    final snapshot = await repo.load();
    expect(snapshot.recentResourceIds, ['b', 'd', 'c']);
    expect(snapshot.recentEntries.first.resourceId, 'b');
    expect(snapshot.recentEntries.first.openedAt, isNotNull);
    expect(
      File(
        p.join(root.path, '.ai-workbench', 'local', 'recent.json'),
      ).existsSync(),
      isTrue,
    );
  });

  test('legacy recent resourceIds are loaded without timestamps', () async {
    final root = await Directory.systemTemp.createTemp('nightelf-meta-legacy-');
    addTearDown(() => root.delete(recursive: true));
    final recentFile = File(
      p.join(root.path, '.ai-workbench', 'local', 'recent.json'),
    );
    await recentFile.parent.create(recursive: true);
    await recentFile.writeAsString(
      '{"version":1,"resourceIds":["legacy-a","legacy-b"]}\n',
    );

    final snapshot = await JsonMetadataRepository(vaultRoot: root).load();
    expect(snapshot.recentResourceIds, ['legacy-a', 'legacy-b']);
    expect(snapshot.recentEntries.every((entry) => entry.openedAt == null), isTrue);
  });

  test('tags are trimmed and deduplicated on save', () async {
    final root = await Directory.systemTemp.createTemp('nightelf-meta-tags-');
    addTearDown(() => root.delete(recursive: true));
    final repo = JsonMetadataRepository(vaultRoot: root);
    await repo.saveResource(
      const ResourceMetadata(
        resourceId: 'prompt-1',
        tags: [' 内容 ', '内容', '发布', ''],
      ),
    );
    final snapshot = await repo.load();
    expect(snapshot.resources['prompt-1']!.tags, ['内容', '发布']);
  });
}
