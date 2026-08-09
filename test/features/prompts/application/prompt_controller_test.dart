import 'dart:io';

import 'package:ai_workbench/features/prompts/application/prompt_controller.dart';
import 'package:ai_workbench/features/prompts/data/file_prompt_repository.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/platform/recording_platform_adapters.dart';

void main() {
  late Directory root;
  late RecordingClipboardService clipboard;
  late PromptController controller;
  var nextId = 0;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('nightelf-prompt-ctrl-');
    clipboard = RecordingClipboardService();
    nextId = 0;
    controller = PromptController(
      repository: FilePromptRepository(
        vaultRoot: root,
        writer: AtomicFileWriter(),
        idFactory: () => 'id-${++nextId}',
      ),
      clipboard: clipboard,
      vaultRootPath: root.path,
    );
  });

  tearDown(() async {
    controller.dispose();
    await root.delete(recursive: true);
  });

  test('copy outputs body only and trash can undo', () async {
    await controller.create(title: '审查', body: '# 角色\n你是审查员。\n');
    expect(controller.document?.id, 'id-1');

    await controller.copyPlainText();
    expect(clipboard.texts.last, '# 角色\n你是审查员。\n');
    await controller.copyMarkdown();
    expect(clipboard.texts.last, '# 角色\n你是审查员。\n');

    final duplicated = await controller.duplicate();
    expect(duplicated.id, 'id-2');
    expect(duplicated.title, '审查 副本');

    final trash = await controller.moveToTrash();
    expect(controller.document, isNull);
    expect(trash, contains('.ai-workbench/local/trash/'));

    final restored = await controller.undoTrash();
    expect(restored.id, 'id-2');
    expect(controller.document?.title, '审查 副本');
  });
}
