import 'dart:io';

import 'package:ai_workbench/features/skills/application/skill_controller.dart';
import 'package:ai_workbench/features/skills/data/file_skill_repository.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../shared/platform/recording_platform_adapters.dart';
import '../../../support/skill_fixture.dart';

void main() {
  late Directory vault;
  late RecordingSystemOpenService systemOpen;
  late SkillController controller;
  var nextId = 0;

  setUp(() async {
    vault = await Directory.systemTemp.createTemp('nightelf-skill-ctrl-');
    systemOpen = RecordingSystemOpenService();
    nextId = 0;
    controller = SkillController(
      repository: FileSkillRepository(
        vaultRoot: vault,
        writer: AtomicFileWriter(),
        idFactory: () => 'id-${++nextId}',
        clock: () => DateTime.utc(2026, 8, 9, 2, 30, 0),
      ),
      systemOpen: systemOpen,
      vaultRootPath: vault.path,
    );
  });

  tearDown(() async {
    controller.dispose();
    await vault.delete(recursive: true);
  });

  test(
    'import opens entry text and supports finder terminal trash undo',
    () async {
      final source = await skillFixture({
        'SKILL.md': '# Apple\n',
        'notes.txt': 'hello\n',
        'assets/icon.png': [1, 2, 3, 4],
        'blob.bin': [9, 9],
      });
      addTearDown(source.dispose);

      final imported = await controller.importDirectory(source.directory);
      expect(imported.entryRelativePath, 'skills/apple-design/SKILL.md');
      expect(controller.previewKind, SkillPreviewKind.text);
      expect(controller.session?.text, '# Apple\n');

      await controller.openNode('skills/apple-design/notes.txt');
      controller.session!.updateText('saved\n');
      await controller.saveSelectedText();
      expect(
        File(
          p.join(vault.path, 'skills/apple-design/notes.txt'),
        ).readAsStringSync(),
        'saved\n',
      );

      await controller.openNode('skills/apple-design/assets/icon.png');
      expect(controller.previewKind, SkillPreviewKind.image);

      await controller.openNode('skills/apple-design/blob.bin');
      expect(controller.previewKind, SkillPreviewKind.binary);
      expect(
        systemOpen.openedPaths.single,
        p.join(vault.path, 'skills/apple-design/blob.bin'),
      );

      await controller.revealInFinder();
      expect(
        systemOpen.revealedPaths.last,
        p.join(vault.path, 'skills/apple-design/blob.bin'),
      );
      await controller.openTerminal();
      expect(
        systemOpen.terminalPaths.single,
        p.join(vault.path, 'skills/apple-design'),
      );

      final trash = await controller.moveToTrash();
      expect(controller.skill, isNull);
      expect(trash, contains('.ai-workbench/local/trash/'));

      final restored = await controller.undoTrash();
      expect(restored.relativeDirectory, 'skills/apple-design');
      expect(controller.skill?.title, 'apple-design');
    },
  );

  test('lazy expand loads nested children once', () async {
    final source = await skillFixture({
      'SKILL.md': '# Root\n',
      'references/motion.md': '# Motion\n',
    });
    addTearDown(source.dispose);
    await controller.importDirectory(source.directory);

    final references = controller.rootChildren.firstWhere(
      (node) => node.name == 'references',
    );
    expect(references.childrenLoaded, isFalse);
    await controller.expandDirectory(references);
    expect(references.childrenLoaded, isTrue);
    expect(references.children.single.name, 'motion.md');

    await controller.expandDirectory(references);
    expect(references.children.length, 1);
  });
}
