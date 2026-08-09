import 'dart:io';

import 'package:ai_workbench/features/links/application/link_controller.dart';
import 'package:ai_workbench/features/links/data/file_link_repository.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/features/workspaces/presentation/workspace_content.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../shared/platform/recording_platform_adapters.dart';

void main() {
  testWidgets('live website resource uses the dedicated link workspace', (
    tester,
  ) async {
    final root = await Directory.systemTemp.createTemp(
      'nightelf-workspace-link-',
    );
    final controller = LinkController(
      repository: FileLinkRepository(
        vaultRoot: root,
        writer: AtomicFileWriter(),
        idFactory: () => 'workspace-link-id',
      ),
      clipboard: RecordingClipboardService(),
      systemOpen: RecordingSystemOpenService(),
      vaultRootPath: root.path,
    );
    addTearDown(() async {
      controller.dispose();
      await root.delete(recursive: true);
    });
    final document = await controller.create(
      title: 'mariuti.com',
      url: 'https://mariuti.com/flutter-shadcn-ui/',
    );
    final resource = WorkbenchResource(
      id: document.id,
      type: ResourceType.websiteLink,
      title: document.title,
      subtitle: document.relativePath,
      isFavorite: false,
      relativePath: document.relativePath,
    );
    await tester.binding.setSurfaceSize(const Size(1100, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MacosApp(
        theme: MacosThemeData.dark(),
        home: MacosWindow(
          child: WorkspaceContent(
            resource: resource,
            vaultRootPath: root.path,
            linkController: controller,
            linkBrowserBuilder: (context, url, onOpenExternally) => ColoredBox(
              key: const ValueKey('workspace-fake-browser'),
              color: const Color(0xFF111820),
              child: Text(url),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('link-workspace-header')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('workspace-fake-browser')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('link-details-inspector')),
      findsOneWidget,
    );
    expect(find.text('链接信息'), findsOneWidget);
    expect(find.text('可编辑 · 自动保存'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
