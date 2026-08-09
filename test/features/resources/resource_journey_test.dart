import 'dart:io';

import 'package:ai_workbench/features/mcp/application/mcp_controller.dart';
import 'package:ai_workbench/features/mcp/data/file_mcp_repository.dart';
import 'package:ai_workbench/features/prompts/application/prompt_controller.dart';
import 'package:ai_workbench/features/prompts/data/file_prompt_repository.dart';
import 'package:ai_workbench/features/skills/application/skill_controller.dart';
import 'package:ai_workbench/features/skills/data/file_skill_repository.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../shared/platform/recording_platform_adapters.dart';
import '../../support/skill_fixture.dart';

void main() {
  late Directory vault;
  var nextId = 0;

  setUp(() async {
    vault = await Directory.systemTemp.createTemp('nightelf-journey-');
    nextId = 0;
  });

  tearDown(() async {
    await vault.delete(recursive: true);
  });

  test('prompt skill and mcp journeys on a temporary vault', () async {
    final clipboard = RecordingClipboardService();
    final systemOpen = RecordingSystemOpenService();
    final prompt = PromptController(
      repository: FilePromptRepository(
        vaultRoot: vault,
        writer: AtomicFileWriter(),
        idFactory: () => 'id-${++nextId}',
      ),
      clipboard: clipboard,
      vaultRootPath: vault.path,
    );
    final skill = SkillController(
      repository: FileSkillRepository(
        vaultRoot: vault,
        writer: AtomicFileWriter(),
        idFactory: () => 'id-${++nextId}',
      ),
      systemOpen: systemOpen,
      vaultRootPath: vault.path,
    );
    final mcp = McpController(
      repository: FileMcpRepository(
        vaultRoot: vault,
        writer: AtomicFileWriter(),
        idFactory: () => 'id-${++nextId}',
      ),
      clipboard: clipboard,
      systemOpen: systemOpen,
      vaultRootPath: vault.path,
    );
    addTearDown(prompt.dispose);
    addTearDown(skill.dispose);
    addTearDown(mcp.dispose);

    await prompt.create(title: '审查', body: '# 角色\n审查员\n');
    await prompt.copyPlainText();
    expect(clipboard.texts.last, '# 角色\n审查员\n');
    final promptCopy = await prompt.duplicate();
    expect(promptCopy.title, '审查 副本');

    final source = await skillFixture({
      'SKILL.md': '# Design\n',
      'notes.md': 'note\n',
    });
    addTearDown(source.dispose);
    final imported = await skill.importDirectory(source.directory);
    expect(imported.entryRelativePath, 'skills/apple-design/SKILL.md');
    await skill.openNode('skills/apple-design/notes.md');
    skill.session!.updateText('saved\n');
    await skill.saveSelectedText();
    expect(
      File(
        p.join(vault.path, 'skills/apple-design/notes.md'),
      ).readAsStringSync(),
      'saved\n',
    );
    await skill.revealInFinder();
    expect(systemOpen.revealedPaths, isNotEmpty);

    await mcp.create(title: 'demo', jsonText: '{"a":1}');
    mcp.session!.updateText('{\n  "mcpServers": {\n');
    await mcp.validate();
    expect(mcp.isValid, isFalse);
    mcp.session!.updateText('{"mcpServers":{}}');
    await mcp.format();
    expect(mcp.isValid, isTrue);
    await mcp.copySafeTemplate();
    expect(clipboard.texts.last, contains('"mcpServers"'));
  });
}
