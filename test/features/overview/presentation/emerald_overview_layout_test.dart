import 'package:ai_workbench/features/overview/presentation/emerald_overview_dashboard.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_shell.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_sidebar.dart';
import 'package:ai_workbench/shared/ui/workbench_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  testWidgets('matches the reference desktop region proportions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1672, 940));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MacosApp(
        theme: MacosThemeData.dark(),
        home: const WorkbenchShadScope(
          child: WorkbenchShell(vaultRootPath: '/reference-vault'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EmeraldOverviewDashboard), findsOneWidget);
    final sidebar = tester.widget<WorkbenchSidebar>(
      find.byType(WorkbenchSidebar),
    );
    expect(sidebar.width, closeTo(340, 8));
    expect(find.text('Nightelf · AI 工作台'), findsOneWidget);
    final logo = tester.widget<Image>(
      find.byKey(const ValueKey('nightelf-sidebar-logo')),
    );
    expect((logo.image as AssetImage).assetName, 'assets/nightelf-logo.png');
    expect(logo.width, 34);
    expect(logo.height, 34);
    expect(logo.fit, BoxFit.contain);
    expect(find.text('最近使用的资源'), findsOneWidget);
    expect(find.text('同步状态'), findsOneWidget);
  });
}
