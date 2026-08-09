import 'package:ai_workbench/features/shell/presentation/workbench_shell.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_sidebar.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  Future<void> pumpShell(WidgetTester tester, ThemeMode themeMode) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MacosApp(
        themeMode: themeMode,
        theme: MacosThemeData.light(),
        darkTheme: MacosThemeData.dark(),
        home: const WorkbenchShell(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the navigation sections and toolbar actions', (
    tester,
  ) async {
    await pumpShell(tester, ThemeMode.dark);

    for (final label in const [
      'AI 提示词',
      'SKILL 文件夹',
      'MCP 配置',
      '网站链接',
      'Workflow 文件',
    ]) {
      expect(
        find.descendant(
          of: find.byType(WorkbenchSidebar),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
    expect(find.text('收藏'), findsOneWidget);
    expect(find.text('最近使用'), findsOneWidget);
    expect(find.text('我的 AI 工作台'), findsOneWidget);
    expect(find.text('⌘K'), findsOneWidget);
    expect(find.text('未配置同步'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is PushButton && widget.semanticLabel == '搜索资源',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is MacosIconButton && widget.semanticLabel == '查看历史记录',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is MacosIconButton && widget.semanticLabel == '切换视图',
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders the shell at desktop size in dark and light themes', (
    tester,
  ) async {
    for (final themeMode in [ThemeMode.dark, ThemeMode.light]) {
      await pumpShell(tester, themeMode);

      expect(tester.takeException(), isNull);
      expect(find.byType(WorkbenchShell), findsOneWidget);
    }
  });
}
