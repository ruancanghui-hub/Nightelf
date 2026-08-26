import 'package:ai_workbench/shared/ui/workbench_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  testWidgets('search trigger invokes onTap and shows shortcut chip', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MacosApp(
        theme: MacosThemeData.dark(),
        home: WorkbenchShadScope(
          child: MacosWindow(
            child: Center(
              child: WorkbenchSearchTrigger(onTap: () => tapped = true),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('⌘K'), findsOneWidget);
    await tester.tap(find.byType(WorkbenchSearchTrigger));
    expect(tapped, isTrue);
  });

  testWidgets('primary button renders child text', (tester) async {
    await tester.pumpWidget(
      MacosApp(
        theme: MacosThemeData.dark(),
        home: WorkbenchShadScope(
          child: MacosWindow(
            child: Center(
              child: WorkbenchButton(
                onPressed: () {},
                child: const Text('Primary'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Primary'), findsOneWidget);
  });

  testWidgets('button label shrinks instead of overflowing a tight width', (
    tester,
  ) async {
    FlutterErrorDetails? overflow;
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) {
        overflow = details;
      }
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    await tester.pumpWidget(
      MacosApp(
        theme: MacosThemeData.dark(),
        home: WorkbenchShadScope(
          child: MacosWindow(
            child: Center(
              child: SizedBox(
                width: 192,
                height: 36,
                child: WorkbenchButton(
                  size: WorkbenchButtonSize.sm,
                  expands: true,
                  onPressed: () {},
                  child: const Text('启用 Git 同步并且再加一些会撑破按钮的长文字'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(overflow, isNull);
    expect(tester.takeException(), isNull);
  });
}
