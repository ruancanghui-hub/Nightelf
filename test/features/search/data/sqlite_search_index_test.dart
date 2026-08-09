import 'package:ai_workbench/features/search/data/sqlite_search_index.dart';
import 'package:ai_workbench/features/search/domain/search_query.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/resource_factories.dart';

void main() {
  test(
    'searches title, tags, description, and content with a type filter',
    () async {
      final index = SqliteSearchIndex.inMemory();
      addTearDown(index.close);
      await index.rebuild([
        promptRecord(
          id: 'p1',
          title: '代码审查助手',
          tags: const ['审查'],
          searchableText: '安全与性能',
        ),
        mcpRecord(id: 'm1', title: '文件服务', searchableText: 'filesystem'),
      ]);

      final hits = await index.query(
        SearchQuery(text: '审查', types: const {ResourceType.prompt}),
      );

      expect(hits.map((e) => e.record.id), ['p1']);
      expect(hits.single.snippet, contains('审查'));
    },
  );

  test('blank query returns an empty list', () async {
    final index = SqliteSearchIndex.inMemory();
    addTearDown(index.close);
    await index.rebuild([
      promptRecord(id: 'p1', title: '代码审查助手', searchableText: '安全'),
    ]);

    final hits = await index.query(const SearchQuery(text: '   '));

    expect(hits, isEmpty);
  });

  test('upsert changes search results', () async {
    final index = SqliteSearchIndex.inMemory();
    addTearDown(index.close);
    await index.rebuild([
      promptRecord(id: 'p1', title: '旧标题', searchableText: '旧内容'),
    ]);

    await index.upsert(
      promptRecord(id: 'p1', title: '新标题性能优化', searchableText: '新内容'),
    );

    final hits = await index.query(const SearchQuery(text: '性能'));
    expect(hits.map((e) => e.record.id), ['p1']);
    expect(hits.single.record.title, '新标题性能优化');
  });

  test('remove deletes both table rows', () async {
    final index = SqliteSearchIndex.inMemory();
    addTearDown(index.close);
    await index.rebuild([
      promptRecord(id: 'p1', title: '代码审查助手', searchableText: '安全'),
      mcpRecord(id: 'm1', title: '文件服务', searchableText: 'filesystem'),
    ]);

    await index.remove('p1');

    final hits = await index.query(const SearchQuery(text: '审查'));
    expect(hits, isEmpty);
    final remaining = await index.query(const SearchQuery(text: '文件'));
    expect(remaining.map((e) => e.record.id), ['m1']);
  });

  test('Chinese tokens match across title and content', () async {
    final index = SqliteSearchIndex.inMemory();
    addTearDown(index.close);
    await index.rebuild([
      promptRecord(
        id: 'p1',
        title: '发布检查',
        description: '上线前核对',
        tags: const ['发布'],
        searchableText: '检查清单包含回归测试',
      ),
    ]);

    final byTitle = await index.query(const SearchQuery(text: '发布'));
    final byContent = await index.query(const SearchQuery(text: '回归'));

    expect(byTitle.map((e) => e.record.id), ['p1']);
    expect(byContent.map((e) => e.record.id), ['p1']);
  });

  test('quoted and star input cannot break the SQL statement', () async {
    final index = SqliteSearchIndex.inMemory();
    addTearDown(index.close);
    await index.rebuild([
      promptRecord(id: 'p1', title: '安全助手', searchableText: 'quote test'),
    ]);

    final hits = await index.query(const SearchQuery(text: '安全" OR *'));

    expect(hits, isA<List>());
  });

  test('tag filter narrows results', () async {
    final index = SqliteSearchIndex.inMemory();
    addTearDown(index.close);
    await index.rebuild([
      promptRecord(
        id: 'p1',
        title: '审查助手',
        tags: const ['代码', '审查'],
        searchableText: '审查流程',
      ),
      promptRecord(
        id: 'p2',
        title: '审查说明',
        tags: const ['文档'],
        searchableText: '审查文档',
      ),
    ]);

    final hits = await index.query(const SearchQuery(text: '审查', tags: {'代码'}));

    expect(hits.map((e) => e.record.id), ['p1']);
  });
}
