import 'package:ai_workbench/shared/ui/workbench_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  testWidgets('tab bar activates and closes chips', (tester) async {
    var activated = '';
    var closed = '';
    await tester.pumpWidget(
      MacosApp(
        theme: MacosThemeData.dark(),
        home: WorkbenchShadScope(
          child: MacosWindow(
            child: WorkbenchTabBar(
              items: [
                WorkbenchTabItem(
                  id: 'a',
                  label: '第一个提示词',
                  selected: true,
                  onActivate: () => activated = 'a',
                  onClose: () => closed = 'a',
                ),
                WorkbenchTabItem(
                  id: 'b',
                  label: 'mariuti.com',
                  selected: false,
                  onActivate: () => activated = 'b',
                  onClose: () => closed = 'b',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('激活标签页：mariuti.com'));
    expect(activated, 'b');
    await tester.tap(find.bySemanticsLabel('关闭标签页：第一个提示词'));
    expect(closed, 'a');
  });

  testWidgets('card renders selected title and trailing', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MacosApp(
        theme: MacosThemeData.dark(),
        home: WorkbenchShadScope(
          child: MacosWindow(
            child: Center(
              child: WorkbenchCard(
                selected: true,
                onTap: () => tapped = true,
                title: const Text('mariuti.com'),
                description: const Text('links/mariuti-com.md'),
                trailing: const Text('收藏'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('mariuti.com'), findsOneWidget);
    expect(find.text('links/mariuti-com.md'), findsOneWidget);
    expect(find.text('收藏'), findsOneWidget);
    await tester.tap(find.text('mariuti.com'));
    expect(tapped, isTrue);
  });
}
