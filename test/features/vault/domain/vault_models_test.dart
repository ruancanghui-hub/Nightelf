import 'dart:io';

import 'package:ai_workbench/features/vault/data/vault_paths.dart';
import 'package:ai_workbench/features/vault/domain/resource_record.dart';
import 'package:ai_workbench/features/vault/domain/vault_handle.dart';
import 'package:ai_workbench/features/vault/domain/vault_manifest.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';
import '../../../support/resource_factories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('manifest JSON round-trips version and id', () {
    const manifest = VaultManifest(version: 1, id: 'vault-1', name: '我的资源库');

    expect(VaultManifest.fromJson(manifest.toJson()), manifest);
  });

  test('resource directories are stable', () {
    expect(VaultPaths.directoryFor(ResourceType.prompt), 'prompts');
    expect(VaultPaths.directoryFor(ResourceType.skill), 'skills');
    expect(VaultPaths.directoryFor(ResourceType.mcp), 'mcp');
    expect(VaultPaths.directoryFor(ResourceType.link), 'links');
    expect(VaultPaths.directoryFor(ResourceType.workflow), 'workflows');
    expect(VaultPaths.directoryFor(ResourceType.launcher), 'launchers');
  });

  test('vault handle exposes its manifest identity', () {
    const manifest = VaultManifest(version: 1, id: 'vault-1', name: '我的资源库');
    final handle = VaultHandle(Directory('/tmp/vault-1'), manifest);

    expect(handle.id, 'vault-1');
    expect(handle.name, '我的资源库');
  });

  test('resource records keep their Vault metadata', () {
    final modifiedAt = DateTime.utc(2026, 8, 8, 12);
    final record = ResourceRecord(
      id: 'prompt-1',
      type: ResourceType.prompt,
      relativePath: 'prompts/release-notes.md',
      title: '发布说明助手',
      description: '生成发布说明',
      tags: const ['release', 'writing'],
      modifiedAt: modifiedAt,
      searchableText: '发布说明助手 生成发布说明 release writing',
    );

    expect(record.id, 'prompt-1');
    expect(record.type, ResourceType.prompt);
    expect(record.relativePath, 'prompts/release-notes.md');
    expect(record.title, '发布说明助手');
    expect(record.description, '生成发布说明');
    expect(record.tags, ['release', 'writing']);
    expect(record.modifiedAt, modifiedAt);
    expect(record.searchableText, '发布说明助手 生成发布说明 release writing');
  });

  test('resource record tags cannot be changed through the record', () {
    final record = ResourceRecord(
      id: 'prompt-1',
      type: ResourceType.prompt,
      relativePath: 'prompts/release-notes.md',
      title: '发布说明助手',
      description: '生成发布说明',
      tags: ['release'],
      modifiedAt: DateTime.utc(2026, 8, 8),
      searchableText: '发布说明助手 生成发布说明 release',
    );

    expect(() => record.tags.add('writing'), throwsUnsupportedError);
  });

  test('resource factories use their matching resource types', () {
    expect(promptRecord().type, ResourceType.prompt);
    expect(skillRecord().type, ResourceType.skill);
    expect(mcpRecord().type, ResourceType.mcp);
    expect(linkRecord().type, ResourceType.link);
    expect(workflowRecord().type, ResourceType.workflow);
    expect(launcherRecord().type, ResourceType.launcher);
  });
}
