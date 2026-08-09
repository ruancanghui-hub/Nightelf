import 'dart:convert';
import 'dart:io';

import 'package:ai_workbench/features/vault/data/resource_scanner.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../support/vault_fixture.dart';

void main() {
  test('scanner maps standard folders to resource types', () async {
    final fixture = await createVaultFixture({
      'prompts/review.md': '---\nid: p1\ntitle: 审查助手\n---\n检查代码',
      'mcp/claude.json': '{"mcpServers": {}}',
      'skills/apple-design/SKILL.md': '# Apple Design',
    });
    addTearDown(fixture.dispose);

    final records = await fixture.scanner.scan(fixture.handle);

    expect(
      records.map((record) => record.type),
      containsAll([ResourceType.prompt, ResourceType.mcp, ResourceType.skill]),
    );
    expect(
      records
          .singleWhere((record) => record.relativePath == 'prompts/review.md')
          .id,
      'p1',
    );
    expect(
      records
          .singleWhere((record) => record.type == ResourceType.skill)
          .relativePath,
      'skills/apple-design',
    );
  });

  test(
    'reads metadata, falls back to names, and sorts deterministically',
    () async {
      final fixture = await createVaultFixture({
        'prompts/zulu.md':
            '---\ntitle: beta\ndescription: 二号\ntags: [b, 二]\n---\nPrompt body',
        'prompts/alpha.md': 'Alpha body',
        'links/docs.md':
            '---\ntitle: API Docs\ndescription: Reference\ntags: docs\n---\nhttps://example.test',
        'workflows/build.mmd': 'flowchart LR\nA --> B',
        'workflows/config.yaml': 'steps: []',
        'workflows/ignored.txt': 'unsupported',
        'mcp/server.json': '{"mcpServers": {}}',
        'mcp/.hidden.json': '{}',
        'mcp/draft.json.nightelf-tmp': '{}',
        'prompts/.private/secret.md': 'hidden',
      });
      addTearDown(fixture.dispose);

      final records = await fixture.scanner.scan(fixture.handle);

      expect(records.map((record) => record.relativePath), [
        'prompts/alpha.md',
        'prompts/zulu.md',
        'mcp/server.json',
        'links/docs.md',
        'workflows/build.mmd',
        'workflows/config.yaml',
      ]);
      final prompt = records.singleWhere(
        (record) => record.relativePath == 'prompts/zulu.md',
      );
      expect(prompt.title, 'beta');
      expect(prompt.description, '二号');
      expect(prompt.tags, ['b', '二']);
      expect(prompt.searchableText, contains('Prompt body'));
      expect(
        records
            .singleWhere((record) => record.relativePath == 'prompts/alpha.md')
            .title,
        'alpha',
      );
      expect(
        records
            .singleWhere((record) => record.relativePath == 'links/docs.md')
            .tags,
        ['docs'],
      );
    },
  );

  test('a new scanner preserves sidecar identities across rescans', () async {
    final fixture = await createVaultFixture({
      'mcp/claude.json': '{"mcpServers": {}}',
    });
    addTearDown(fixture.dispose);

    final first = await fixture.scanner.scan(fixture.handle);
    final second = await ResourceScanner().scan(fixture.handle);

    expect(second.single.id, first.single.id);
    expect(first.single.id, isNotEmpty);
    final index = File(
      p.join(fixture.root.path, '.ai-workbench/resources/index.json'),
    );
    expect(await index.exists(), isTrue);
    final decoded =
        jsonDecode(await index.readAsString()) as Map<String, Object?>;
    expect(decoded['version'], 1);
  });

  test('ignores a skill symlink that resolves outside the Vault', () async {
    final fixture = await createVaultFixture({
      'skills/local/SKILL.md': '# Local',
    });
    addTearDown(fixture.dispose);
    final external = await Directory.systemTemp.createTemp(
      'nightelf-external-skill-',
    );
    addTearDown(() async {
      if (await external.exists()) {
        await external.delete(recursive: true);
      }
    });
    await File(p.join(external.path, 'SKILL.md')).writeAsString('# External');
    await Link(
      p.join(fixture.root.path, 'skills', 'external'),
    ).create(external.path);

    final records = await fixture.scanner.scan(fixture.handle);

    expect(records.map((record) => record.title), ['local']);
  });
}
