import 'dart:ui' show Tristate;

import 'package:ai_workbench/features/shell/presentation/workbench_shell.dart';
import 'package:flutter/widgets.dart' show Size, SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  Future<void> pumpShell(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MacosApp(theme: MacosThemeData.light(), home: const WorkbenchShell()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> disposeShell(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets('selecting a sidebar destination opens its resource tab', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is PushButton && widget.semanticLabel == '导航：MCP 配置',
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1));

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is PushButton && widget.semanticLabel == '激活标签页：本地文档 MCP',
      ),
      findsOneWidget,
    );
    expect(find.text('资源 ID：mcp-local-docs'), findsOneWidget);
    await disposeShell(tester);
  });

  testWidgets('closing the final tab clears the inspector', (tester) async {
    await pumpShell(tester);

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is MacosIconButton && widget.semanticLabel == '关闭标签页：发布说明助手',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('选择资源以查看详细信息'), findsOneWidget);
    expect(find.text('资源 ID：prompt-release-notes'), findsNothing);
    await disposeShell(tester);
  });

  testWidgets('active tab exposes selected semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpShell(tester);

    final activeTab = find.byWidgetPredicate(
      (widget) =>
          widget is PushButton && widget.semanticLabel == '激活标签页：发布说明助手',
    );

    try {
      expect(
        tester.getSemantics(activeTab).flagsCollection.isSelected,
        Tristate.isTrue,
      );
    } finally {
      semantics.dispose();
    }
    await disposeShell(tester);
  });
}
