import 'package:ai_workbench/app/ai_workbench_app.dart';
import 'package:ai_workbench/app/theme/workbench_theme.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  testWidgets('renders the AI Workbench application title', (tester) async {
    await tester.pumpWidget(const AiWorkbenchApp());
    await tester.pump(Duration.zero);

    expect(
      tester.widget<MacosApp>(find.byType(MacosApp)).title,
      'AI Workbench',
    );
    expect(find.text('AI Workbench'), findsOneWidget);
  });

  testWidgets('uses the dark workbench theme by default', (tester) async {
    await tester.pumpWidget(const AiWorkbenchApp());
    await tester.pump(Duration.zero);

    expect(
      tester.widget<AiWorkbenchApp>(find.byType(AiWorkbenchApp)).themeMode,
      ThemeMode.dark,
    );
  });

  testWidgets('can render with the light workbench theme', (tester) async {
    await tester.pumpWidget(const AiWorkbenchApp(themeMode: ThemeMode.light));
    await tester.pump(Duration.zero);

    expect(find.text('AI Workbench'), findsOneWidget);
  });

  test('provides distinct dark and light macOS theme tokens', () {
    expect(WorkbenchTheme.dark().brightness, Brightness.dark);
    expect(WorkbenchTheme.dark().canvasColor, const Color(0xFF1C1C1E));
    expect(WorkbenchTheme.light().brightness, Brightness.light);
    expect(WorkbenchTheme.light().canvasColor, const Color(0xFFF5F5F7));
  });
}
