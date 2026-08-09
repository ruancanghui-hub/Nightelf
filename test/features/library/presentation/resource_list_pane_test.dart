import 'package:ai_workbench/features/library/presentation/resource_list_pane.dart';
import 'package:ai_workbench/features/shell/application/workbench_controller.dart';
import 'package:ai_workbench/shared/ui/workbench_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  testWidgets('filters the visible mock resources by title or subtitle', (
    tester,
  ) async {
    final controller = WorkbenchController();

    await tester.pumpWidget(
      MacosApp(
        theme: MacosThemeData.light(),
        home: WorkbenchShadScope(
          child: MacosWindow(
            child: ResourceListPane(
              controller: controller,
              onResourceSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('★ 发布说明助手'), findsOneWidget);
    expect(find.text('UX 评审'), findsOneWidget);

    await tester.enterText(find.byType(WorkbenchInput), '可访问性');
    await tester.pump();

    expect(find.text('★ 发布说明助手'), findsNothing);
    expect(find.text('UX 评审'), findsOneWidget);
  });
}
