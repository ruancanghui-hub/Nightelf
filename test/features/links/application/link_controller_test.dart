import 'dart:io';

import 'package:ai_workbench/features/links/application/link_controller.dart';
import 'package:ai_workbench/features/links/data/file_link_repository.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:ai_workbench/shared/platform/floating_bubble_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/platform/recording_platform_adapters.dart';

void main() {
  late Directory root;
  late RecordingClipboardService clipboard;
  late RecordingSystemOpenService systemOpen;
  late RecordingFloatingBubbleService bubbles;
  late LinkController controller;
  var nextId = 0;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('nightelf-link-ctrl-');
    clipboard = RecordingClipboardService();
    systemOpen = RecordingSystemOpenService();
    bubbles = RecordingFloatingBubbleService();
    nextId = 0;
    controller = LinkController(
      repository: FileLinkRepository(
        vaultRoot: root,
        writer: AtomicFileWriter(),
        idFactory: () => 'id-${++nextId}',
      ),
      clipboard: clipboard,
      systemOpen: systemOpen,
      floatingBubbles: bubbles,
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

  test('rename title and toggle floating bubble', () async {
    await controller.create(
      title: '旧标题',
      url: 'https://example.com',
    );
    final renamed = await controller.rename('新标题');
    expect(renamed.title, '新标题');
    expect(renamed.relativePath, 'links/新标题.md');

    await controller.setFloatingBubble(true);
    expect(controller.isFloatingBubble, isTrue);
    expect(bubbles.shown.single.url, 'https://example.com');

    await controller.setFloatingBubble(false);
    expect(controller.isFloatingBubble, isFalse);
    expect(bubbles.hidden, contains(renamed.id));
  });

  test('rename title still works when draft URL is temporarily invalid', () async {
    await controller.create(
      title: '旧标题',
      url: 'https://example.com',
    );
    controller.updateDraftUrl('javascript:alert(1)');
    final renamed = await controller.rename('自定义名称');
    expect(renamed.title, '自定义名称');
    expect(renamed.uri.toString(), 'https://example.com');
    expect(controller.document?.title, '自定义名称');
  });

  test('native bubble dismiss persists floatingBubble false', () async {
    await controller.create(
      title: '示例',
      url: 'https://example.com',
    );
    await controller.setFloatingBubble(true);
    expect(controller.isFloatingBubble, isTrue);

    bubbles.simulateDismiss(controller.document!.id);
    final deadline = DateTime.now().add(const Duration(seconds: 1));
    while (controller.isFloatingBubble && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    expect(controller.isFloatingBubble, isFalse);
    expect(bubbles.dismissed, contains(controller.document!.id));
  });
}
