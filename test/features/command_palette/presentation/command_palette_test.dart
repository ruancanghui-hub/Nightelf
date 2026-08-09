import 'package:ai_workbench/features/shell/presentation/workbench_shell.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  testWidgets('⌘K opens a palette that searches all mock resources', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MacosApp(theme: MacosThemeData.light(), home: const WorkbenchShell()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('命令面板'), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('命令面板'), findsOneWidget);

    final paletteSearch = find.byWidgetPredicate(
      (widget) => widget is MacosSearchField && widget.placeholder == '搜索所有资源',
    );
    await tester.enterText(paletteSearch, 'Apple');
    await tester.pump();

    expect(find.text('Apple 人机界面指南'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
