import 'dart:io';

import 'package:ai_workbench/features/mcp/application/mcp_controller.dart';
import 'package:ai_workbench/features/mcp/data/file_mcp_repository.dart';
import 'package:ai_workbench/features/mcp/domain/json_diagnostic.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../shared/platform/recording_platform_adapters.dart';

void main() {
  late Directory root;
  late RecordingClipboardService clipboard;
  late RecordingSystemOpenService systemOpen;
  late McpController controller;
  var nextId = 0;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('nightelf-mcp-ctrl-');
    clipboard = RecordingClipboardService();
    systemOpen = RecordingSystemOpenService();
    nextId = 0;
    controller = McpController(
      repository: FileMcpRepository(
        vaultRoot: root,
        writer: AtomicFileWriter(),
        idFactory: () => 'id-${++nextId}',
        clock: () => DateTime.utc(2026, 8, 9, 2, 30, 0),
      ),
      clipboard: clipboard,
      systemOpen: systemOpen,
      vaultRootPath: root.path,
    );
  });

  tearDown(() async {
    controller.dispose();
    await root.delete(recursive: true);
  });

  test('format safe copy terminal trash undo and full copy blocked', () async {
    await controller.create(title: 'demo', jsonText: '{"mcpServers":{}}');
    expect(controller.document?.id, 'id-1');

    await controller.format();
    expect(controller.session?.text, '{\n  "mcpServers": {}\n}\n');
    expect(controller.isValid, isTrue);

    await controller.copySafeTemplate();
    expect(clipboard.texts.last, '{\n  "mcpServers": {}\n}\n');

    await expectLater(
      controller.requestFullCopy(),
      throwsA(isA<FullCopyUnavailable>()),
    );

    await controller.openTerminal();
    expect(systemOpen.terminalPaths.single, p.join(root.path, 'mcp'));

    controller.session!.updateText('{\n  "mcpServers": {\n');
    await controller.validate();
    expect(controller.isValid, isFalse);
    expect(controller.diagnostic, isNotNull);

    final duplicated = await controller.duplicate();
    expect(duplicated.id, 'id-2');

    final trash = await controller.moveToTrash();
    expect(controller.document, isNull);
    expect(trash, contains('.ai-workbench/local/trash/'));

    final restored = await controller.undoTrash();
    expect(restored.id, 'id-2');
  });
}
