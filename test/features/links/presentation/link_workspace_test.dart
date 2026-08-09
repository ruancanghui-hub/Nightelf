import 'dart:io';

import 'package:ai_workbench/features/links/application/link_controller.dart';
import 'package:ai_workbench/features/links/data/file_link_repository.dart';
import 'package:ai_workbench/features/links/presentation/link_workspace.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:ai_workbench/shared/ui/workbench_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../shared/platform/recording_platform_adapters.dart';

void main() {
  late Directory root;
  late RecordingClipboardService clipboard;
  late RecordingSystemOpenService systemOpen;
  late LinkController controller;
  late WorkbenchResource resource;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('nightelf-link-workspace-');
    clipboard = RecordingClipboardService();
    systemOpen = RecordingSystemOpenService();
    controller = LinkController(
      repository: FileLinkRepository(
        vaultRoot: root,
        writer: AtomicFileWriter(),
        idFactory: () => 'link-id',
      ),
      clipboard: clipboard,
      systemOpen: systemOpen,
      vaultRootPath: root.path,
    );
    final document = await controller.create(
      title: 'mariuti.com',
      url: 'https://mariuti.com/flutter-shadcn-ui/',
      tags: const ['Flutter', 'UI 组件'],
      notes: 'Flutter Shadcn UI 组件文档',
    );
    resource = WorkbenchResource(
      id: document.id,
      type: ResourceType.websiteLink,
      title: document.title,
      subtitle: document.relativePath,
      isFavorite: false,
      relativePath: document.relativePath,
    );
  });

  tearDown(() async {
    controller.dispose();
    await root.delete(recursive: true);
  });

  Future<void> pumpWorkspace(
    WidgetTester tester, {
    Size size = const Size(1200, 800),
    Future<void> Function(String resourceId)? onToggleFavorite,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MacosApp(
        theme: MacosThemeData.dark(),
        home: WorkbenchShadScope(
          child: MacosWindow(
            child: LinkWorkspace(
              controller: controller,
              resource: resource,
              onToggleFavorite: onToggleFavorite,
              browserBuilder: (context, url, onOpenExternally) => ColoredBox(
                key: const ValueKey('fake-link-browser'),
                color: const Color(0xFF111820),
                child: Center(child: Text('browser:$url')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('wide link workspace matches browser and inspector hierarchy', (
    tester,
  ) async {
    await pumpWorkspace(tester);

    expect(find.byKey(const ValueKey('link-workspace-header')), findsOneWidget);
    expect(find.byKey(const ValueKey('link-browser-pane')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('link-details-inspector')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('fake-link-browser')), findsOneWidget);
    expect(find.text('mariuti.com'), findsWidgets);
    expect(find.text('https://mariuti.com/flutter-shadcn-ui/'), findsWidgets);
    expect(find.text('已保存'), findsOneWidget);
    expect(find.text('链接信息'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);
    expect(find.text('UI 组件'), findsOneWidget);
    expect(find.text('Flutter Shadcn UI 组件文档'), findsOneWidget);
    expect(find.text('收藏'), findsOneWidget);
    expect(find.text('未收藏'), findsOneWidget);
    expect(find.text('最后访问'), findsOneWidget);
    expect(find.text('刚刚'), findsOneWidget);

    final browserRect = tester.getRect(
      find.byKey(const ValueKey('link-browser-pane')),
    );
    final inspectorRect = tester.getRect(
      find.byKey(const ValueKey('link-details-inspector')),
    );
    final headerRect = tester.getRect(
      find.byKey(const ValueKey('link-workspace-header')),
    );
    expect(browserRect.right, lessThanOrEqualTo(inspectorRect.left));
    expect(inspectorRect.top, lessThan(browserRect.top));
    expect((headerRect.top - inspectorRect.top).abs(), lessThan(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('copy external favorite and rename controls keep real behavior', (
    tester,
  ) async {
    final toggled = <String>[];
    await pumpWorkspace(
      tester,
      onToggleFavorite: (id) async => toggled.add(id),
    );

    await tester.tap(find.byKey(const ValueKey('link-copy-button')));
    await tester.tap(find.byKey(const ValueKey('link-external-button')));
    await tester.tap(find.byKey(const ValueKey('link-favorite-button')));
    await tester.pump();

    expect(clipboard.texts.single, 'https://mariuti.com/flutter-shadcn-ui/');
    expect(
      systemOpen.openedUrls.single.toString(),
      'https://mariuti.com/flutter-shadcn-ui/',
    );
    expect(toggled, ['link-id']);

    final titleField = tester.widget<WorkbenchInput>(
      find.byKey(const ValueKey('link-title-field')),
    );
    expect(titleField.onSubmitted, isNotNull);
    await tester.runAsync(() async {
      titleField.onSubmitted!.call('Flutter Shadcn UI');
      final deadline = DateTime.now().add(const Duration(seconds: 1));
      while (controller.document?.title != 'Flutter Shadcn UI' &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });
    await tester.pump();

    expect(controller.document?.title, 'Flutter Shadcn UI');
  });

  testWidgets('compact link workspace stacks without losing core content', (
    tester,
  ) async {
    await pumpWorkspace(tester, size: const Size(640, 900));

    expect(find.byKey(const ValueKey('link-browser-pane')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('link-details-inspector')),
      findsOneWidget,
    );
    final browserRect = tester.getRect(
      find.byKey(const ValueKey('link-browser-pane')),
    );
    final inspectorRect = tester.getRect(
      find.byKey(const ValueKey('link-details-inspector')),
    );
    expect(inspectorRect.top, greaterThan(browserRect.bottom));
    expect(tester.takeException(), isNull);
  });
}
