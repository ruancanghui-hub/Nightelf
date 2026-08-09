import 'dart:io';

import 'package:ai_workbench/features/links/application/link_controller.dart';
import 'package:ai_workbench/features/links/data/file_link_repository.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/platform/recording_platform_adapters.dart';

void main() {
  late Directory root;
  late RecordingClipboardService clipboard;
  late RecordingSystemOpenService systemOpen;
  late LinkController controller;
  var nextId = 0;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('nightelf-link-ctrl-');
    clipboard = RecordingClipboardService();
    systemOpen = RecordingSystemOpenService();
    nextId = 0;
    controller = LinkController(
      repository: FileLinkRepository(
        vaultRoot: root,
        writer: AtomicFileWriter(),
        idFactory: () => 'id-${++nextId}',
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

  test('paste clipboard link copy and open externally', () async {
    clipboard.nextReadText = 'https://example.com/docs';
    final created = await controller.createFromClipboard();
    expect(created.uri.toString(), 'https://example.com/docs');
    expect(created.title, 'example.com');

    await controller.copyUrl();
    expect(clipboard.texts.last, 'https://example.com/docs');

    await controller.openExternally();
    expect(systemOpen.openedUrls.single.toString(), 'https://example.com/docs');

    clipboard.nextReadText = 'javascript:alert(1)';
    await expectLater(controller.createFromClipboard(), throwsStateError);
    expect(controller.errorMessage, '仅支持 http 或 https 链接');
  });
}
