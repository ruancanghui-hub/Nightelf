import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_shell.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_sidebar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

Future<void> _disposeShell(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(Duration.zero);
  await tester.pump(Duration.zero);
}

void main() {
  testWidgets('shell exposes core semantic labels', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MacosApp(theme: MacosThemeData.light(), home: const WorkbenchShell()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(
      find.byWidgetPredicate(
        (widget) => widget is PushButton && widget.semanticLabel == '搜索资源',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is PushButton && widget.semanticLabel == '同步',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is PushButton && widget.semanticLabel == '切换检查器',
      ),
      findsOneWidget,
    );
    for (final label in [
      '导航：AI 提示词',
      '导航：SKILL 文件夹',
      '导航：MCP 配置',
      '导航：网站链接',
      '导航：Workflow 文件',
    ]) {
      expect(
        find.byWidgetPredicate(
          (widget) => widget is PushButton && widget.semanticLabel == label,
        ),
        findsOneWidget,
      );
    }
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is MacosIconButton &&
            widget.semanticLabel == '关闭标签页：发布说明助手',
      ),
      findsOneWidget,
    );

    await _disposeShell(tester);
  });

  testWidgets('compact width collapses inspector and sidebar labels', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(740, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MacosApp(theme: MacosThemeData.light(), home: const WorkbenchShell()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(
      find.descendant(
        of: find.byType(WorkbenchSidebar),
        matching: find.text('AI 提示词'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(WorkbenchSidebar),
        matching: find.text('提'),
      ),
      findsOneWidget,
    );
    expect(find.text('检查器'), findsNothing);
    expect(find.text('显示检查器'), findsOneWidget);

    await _disposeShell(tester);
  });

  testWidgets('reduced motion still opens the command palette', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MacosApp(
        theme: MacosThemeData.light(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(1440, 1024),
            disableAnimations: true,
          ),
          child: const WorkbenchShell(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is PushButton && widget.semanticLabel == '搜索资源',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('命令面板'), findsOneWidget);

    await _disposeShell(tester);
  });

  testWidgets('favorite semantic remains for vault-like rows', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MacosApp(
        theme: MacosThemeData.light(),
        home: WorkbenchShell(
          resources: const [
            WorkbenchResource(
              id: 'a',
              type: ResourceType.aiPrompt,
              title: 'A',
              subtitle: '',
              isFavorite: false,
            ),
            WorkbenchResource(
              id: 'b',
              type: ResourceType.aiPrompt,
              title: 'B',
              subtitle: '',
              isFavorite: false,
            ),
          ],
          onToggleFavorite: (_) async {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(
      find.byWidgetPredicate(
        (widget) => widget is PushButton && widget.semanticLabel == '收藏：A',
      ),
      findsOneWidget,
    );

    await _disposeShell(tester);
  });
}
