import 'package:ai_workbench/features/shell/presentation/workbench_shell.dart';
import 'package:ai_workbench/shared/ui/workbench_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

Future<void> _pumpShell(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1440, 1024));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MacosApp(
      theme: MacosThemeData.light(),
      home: const WorkbenchShadScope(child: WorkbenchShell()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

Future<void> _disposeShell(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(Duration.zero);
  await tester.pump(Duration.zero);
}

void main() {
  testWidgets('command K opens and Escape closes the command palette', (
    tester,
  ) async {
    await _pumpShell(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('命令面板'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('命令面板'), findsNothing);
    await _disposeShell(tester);
  });

  testWidgets('command W closes the active tab', (tester) async {
    await _pumpShell(tester);
    expect(find.text('资源 ID：prompt-release-notes'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('选择资源以查看详细信息'), findsOneWidget);
    await _disposeShell(tester);
  });
}
