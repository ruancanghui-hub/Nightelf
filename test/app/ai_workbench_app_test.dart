import 'package:ai_workbench/app/ai_workbench_app.dart';
import 'package:ai_workbench/app/theme/workbench_theme.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  testWidgets('renders the Nightelf application title', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AiWorkbenchApp(hasVault: true, skipRestore: true),
      ),
    );
    await tester.pump(Duration.zero);

    expect(
      tester.widget<MacosApp>(find.byType(MacosApp)).title,
      'Nightelf · AI 工作台',
    );
    expect(find.text('Nightelf · AI 工作台'), findsOneWidget);
  });

  testWidgets('uses the dark workbench theme by default', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AiWorkbenchApp(hasVault: true, skipRestore: true),
      ),
    );
    await tester.pump(Duration.zero);

    expect(
      tester.widget<AiWorkbenchApp>(find.byType(AiWorkbenchApp)).themeMode,
      ThemeMode.dark,
    );
  });

  testWidgets('uses the emerald welcome screen before a Vault is opened', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: AiWorkbenchApp(skipRestore: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('开启你的绿光工作台'), findsOneWidget);
    expect(find.text('创建 Vault'), findsOneWidget);
    expect(find.text('打开 Vault'), findsOneWidget);
  });

  testWidgets('can render with the light workbench theme', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AiWorkbenchApp(
          themeMode: ThemeMode.light,
          hasVault: true,
          skipRestore: true,
        ),
      ),
    );
    await tester.pump(Duration.zero);

    expect(find.text('Nightelf · AI 工作台'), findsOneWidget);
  });

  test('provides distinct dark and light macOS theme tokens', () {
    expect(WorkbenchTheme.dark().brightness, Brightness.dark);
    expect(WorkbenchTheme.dark().canvasColor, const Color(0xFF1C1C1E));
    expect(WorkbenchTheme.light().brightness, Brightness.light);
    expect(WorkbenchTheme.light().canvasColor, const Color(0xFFF5F5F7));
  });
}
